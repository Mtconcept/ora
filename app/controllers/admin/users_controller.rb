class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[show edit update suspend reactivate deactivate]
  before_action :require_super_admin, only: %i[new create deactivate]

  def index
    @users = User.kept
    if params[:role] == "admin"
      @users = @users.where(role: %w[admin super_admin])
    elsif User::ROLES.include?(params[:role])
      @users = @users.where(role: params[:role])
    end
    @users = @users.where(status: params[:status]) if User::STATUSES.include?(params[:status])
    @users = @users.where("created_at >= ?", 30.days.ago) if params[:filter] == "recent"
    if params[:q].present?
      query = "%#{User.sanitize_sql_like(params[:q].strip)}%"
      @users = @users.where("first_name LIKE :q OR last_name LIKE :q OR email LIKE :q OR phone LIKE :q OR CAST(id AS TEXT) LIKE :q", q: query)
    end
    sort_columns = { "id" => "id", "name" => "first_name", "email" => "email", "role" => "role", "status" => "status", "joined" => "created_at" }
    @sort = sort_columns.key?(params[:sort]) ? params[:sort] : "joined"
    @direction = params[:direction] == "asc" ? "asc" : "desc"
    @users = @users.order(Arel.sql("#{sort_columns.fetch(@sort)} #{@direction}"))
    @total_count = @users.count
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @per_page = 20
    @users = @users.limit(@per_page).offset((@page - 1) * @per_page)
  end

  def show
    @audit_events = AdminAuditEvent.where(target_user: @user).includes(:actor).order(created_at: :desc).limit(25)
  end

  def new
    @user = User.new(role: "admin", status: "active")
  end

  def create
    @user = User.new(user_params)
    @user.role = requested_role
    @user.status = requested_status
    normalize_admin_flag
    unless @user.staff? && permitted_role?(@user.role)
      @user.errors.add(:role, "must be a team role; patient accounts are created by patients")
      return render :new, status: :unprocessable_entity
    end
    if @user.staff? && @user.password.blank?
      @user.errors.add(:password, "is required for team members")
      return render :new, status: :unprocessable_entity
    end
    if @user.save
      audit!("user_created", target: @user, current: audit_snapshot(@user))
      redirect_to admin_user_path(@user), notice: "Team member created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    previous = audit_snapshot(@user)
    attributes = user_params
    attributes.delete(:password) if attributes[:password].blank?
    proposed_role = requested_role
    proposed_status = requested_status
    unless permitted_role?(proposed_role) && role_change_safe?(proposed_role)
      @user.errors.add(:role, "cannot be assigned by your account")
      return render :edit, status: :unprocessable_entity
    end
    if @user == current_admin && proposed_status != "active"
      @user.errors.add(:status, "cannot be changed on your own account")
      return render :edit, status: :unprocessable_entity
    end
    @user.assign_attributes(attributes)
    @user.role = proposed_role
    @user.status = proposed_status
    normalize_admin_flag
    if @user.save
      audit!("user_updated", target: @user, previous: previous, current: audit_snapshot(@user))
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def suspend
    return blocked_self_action if @user == current_admin

    change_status!("suspended", "user_suspended", "User suspended.")
  end

  def reactivate
    change_status!("active", "user_reactivated", "User reactivated.")
  end

  def deactivate
    return blocked_self_action if @user == current_admin
    return redirect_to(admin_user_path(@user), alert: "The last super admin cannot be deactivated.") if last_super_admin?(@user)

    previous = audit_snapshot(@user)
    @user.update!(status: "deactivated", deleted_at: Time.current)
    audit!("user_deactivated", target: @user, previous: previous, current: audit_snapshot(@user))
    redirect_to admin_users_path, notice: "User deactivated. Their record remains in the audit history."
  end

  private

  def set_user
    @user = User.kept.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :password, :password_confirmation)
  end

  def requested_role
    role = params.dig(:user, :role).to_s
    User::ROLES.include?(role) ? role : (@user&.role || "customer")
  end

  def requested_status
    status = params.dig(:user, :status).to_s
    User::STATUSES.include?(status) ? status : (@user&.status || "active")
  end

  def permitted_role?(role)
    User::ROLES.include?(role) && (current_admin.super_admin? || role == "customer")
  end

  def role_change_safe?(proposed_role)
    !(@user.super_admin? && proposed_role != "super_admin" && last_super_admin?(@user))
  end

  def last_super_admin?(user)
    user.super_admin? && User.staff.where(role: "super_admin", status: "active").count == 1
  end

  def normalize_admin_flag
    @user.admin = @user.staff?
  end

  def change_status!(status, action, notice)
    if @user.super_admin? && status != "active" && last_super_admin?(@user)
      return redirect_to admin_user_path(@user), alert: "The last super admin must remain active."
    end
    previous = audit_snapshot(@user)
    @user.update!(status: status)
    audit!(action, target: @user, previous: previous, current: audit_snapshot(@user))
    redirect_to admin_user_path(@user), notice: notice
  end

  def blocked_self_action
    redirect_to admin_user_path(@user), alert: "You cannot suspend or deactivate your own account."
  end

  def audit_snapshot(user)
    user.attributes.slice("first_name", "last_name", "email", "phone", "role", "status", "deleted_at")
  end
end
