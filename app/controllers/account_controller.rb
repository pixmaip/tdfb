class AccountController < ApplicationController
  def search
    render json: Account.search(params[:term]).map { |a| { label: a.autocomplete_text, value: a.id } }
  end

  def show
    @account = Account.find(params[:id])
  end

  def exists
    render json: Account.where(trigramme: params[:trigramme].upcase).exists?
  end

  def log
    @account = Account.find(params[:id])
    amount = params[:amount].to_f
    fail TdbException, 'Amount must be positive!' if amount < 0
    require_admin! if amount > 20 # 20 euros
    Transaction.log(@account, @bank, amount, comment: params[:comment], admin: @admin)
    render_redirect_to
  end

  def credit
    @account = Account.find(params[:id])
    amount = params[:amount].to_f
    fail TdbException, 'Amount must be positive!' if amount < 0
    require_admin!
    comment = params[:commit]
    comment += " - #{params[:comment]}" if params[:comment] && !params[:comment].empty?
    Transaction.log(@account, @bank, -amount, comment: comment, admin: @admin)
    render_redirect_to
  end

  def clopes
    @account = Account.find(params[:id])
    clope = Clope.find(params[:clope_id])
    quantity = params[:quantity].to_i
    require_admin! if quantity * clope.prix > 2000
    clope.sell(@account, quantity, admin: @admin)
    render_redirect_to
  end

  def set_nickname
    @account = Account.find(params[:id])
    require_admin!
    @account.update(nickname: params[:nickname].strip)
    render_redirect_to
  end

  def set_trigramme
    @account = Account.find(params[:id])
    trigramme = params[:trigramme].strip.upcase
    fail TdbException, 'Trigramme must have three letters' unless trigramme.size == 3
    require_admin!
    @account.update(trigramme: trigramme)
    render_redirect_to
  end

  def transfer
    @account = Account.find(params[:id])
    amount = params[:amount].to_f
    fail TdbException, 'Amount must be positive!' if amount < 0
    require_admin!
    receiver = Account.find_by(trigramme: params[:receiver].upcase)
    fail TdbException, "Trigramme #{params[:receiver].upcase} is unknown" unless receiver
    fail TdbException, 'Sender and recipient are the same' if receiver.id == @account.id
    Transaction.log(@account, receiver, amount, comment: params[:comment], admin: @admin)
    render_redirect_to
  end

  private

  def render_redirect_to
    respond_to do |format|
      format.html { redirect_to action: :show }
      format.js { return render text: 'location.reload();' }
    end
  end
end
