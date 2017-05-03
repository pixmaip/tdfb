require 'digest/md5'

class ApplicationController < ActionController::Base
  AUTH_EXPIRES = 20.seconds
  include Chart

  before_action do
    require_admin!(:log_eleve) if Rails.env.production?
  end

  protect_from_forgery with: :exception
  before_action :load_bank

  rescue_from TdbException do |mes|
    render json: mes.to_h, status: 400
  end

  rescue_from AuthException do
    # Just to stop propagation
  end

  def index
    @chart_globals = Chart.theme(session['chart_theme'], session['theme'])
    @transactions_volume = Chart.transactions_volume(7, @bank)
    @best_consumers = Chart.best_consumers(7, @bank)
    @scatter_plot = Chart.scatter_plot
    @heat_map = Chart.heat_map(7, @chart_globals)
  end

  def login
    session[:expire_at] = Time.current + 24.hours # To avoid first auth bug
    render layout: false
  end

  def switch_theme
    session['theme'] = params['theme'] if params['theme']
    session['theme'] = nil if params['theme'] == 'bootstrap'
    session['chart_theme'] = params['chart_theme'] if params['chart_theme']
    redirect_to :back
  end

  def create_github_issue
    IssueMailer.issue(params[:name], params[:email], params[:feedback_title], params[:feedback_body]).deliver_now
    redirect_to :back
  end

  private

  def redirect_to_index
    redirect_to_url '/'
  end

  def redirect_to_url(url)
    respond_to do |format|
      format.html { redirect_to url }
      format.js { return render text: "window.location.href = '#{url}';" }
    end
  end

  def redirect_to_trigramme(trigramme)
    redirect_to_url "/account/#{trigramme}"
  end

  def load_bank
    session[:bank_id] ||= 1
    session[:bank] ||= 'BOB'
    @bank = Account.find(session[:bank_id])
  end

  def require_admin!(right)
    authenticate_with_http_basic do |username, password|
      if session[:expire_at].nil? || session[:expire_at] < Time.current
        session[:expire_at] = Time.current + 24.hours
        # Will be reset after first successfull login. If this delay is too short, what happens is than the pop-up appears and
        # when the user finishes typing, the delay has already expired, and the authentication attempt will be rejected whether the
        # credentials are correct or not.
        request_http_basic_authentication
        fail AuthException
      end
      @admin = Admin.joins(:account).includes(:right).find_by(accounts: { trigramme: username })
      if @admin.nil?
        response.header['auth_reason'] = "Unknown admin with trigramme #{username}"
        false
      elsif Digest::MD5.hexdigest(password) != @admin.passwd
        response.header['auth_reason'] = "Wrong password for #{username}"
        false
      elsif !@admin.right[right]
        response.header['auth_reason'] = 'You don\'t have the right to do this'
        false
      else
        session[:expire_at] = Time.current + AUTH_EXPIRES
        true
      end
    end || ((session[:expire_at] = Time.current + 24.hours) && request_http_basic_authentication && fail(AuthException))
  end
end
