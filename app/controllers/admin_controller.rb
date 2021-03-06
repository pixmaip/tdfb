require 'digest/md5'

class AdminController < ApplicationController
  def set_bank
    account = Account.find_by(trigramme: params[:trigramme].upcase)
    fail TdbException, I18n.t('exception.no_account_for_trigramme', trigramme: params[:trigramme].upcase) if account.nil?
    fail TdbException, I18n.t('exception.account_is_not_a_binet') unless account.binet?
    require_admin!(:banque_binet)
    session[:bank_id] = account.id
    session[:bank] = account.trigramme
    redirect_to_trigramme(account.trigramme)
  end

  def index
    require_admin!(:gestion_admin)
    @admins = Admin.joins(:account).includes(:account).includes(:right).order('admins.permissions, accounts.promo').all
    @rights = Right.order(:permissions).all
  end

  def change_password
    admin = Admin.joins(:account).includes(:account).find_by(accounts: { trigramme: params[:trigramme] })
    fail TdbException, I18n.t('exception.account_is_not_admin', trigramme: params[:trigramme].upcase) unless admin
    fail TdbException, I18n.t('exception.wrong_password') unless Digest::MD5.hexdigest(params[:password]) == admin.passwd
    fail TdbException, I18n.t('exception.passwords_do_not_match') unless params[:new_password] == params[:new_password_again]
    admin.update(passwd: Digest::MD5.hexdigest(params[:new_password]))
    redirect_to_url '/'
  end

  def create_admin
    account = Account.find_by(trigramme: params[:trigramme].upcase)
    fail TdbException, I18n.t('exception.no_account_for_trigramme', trigramme: params[:trigramme].upcase) unless account
    fail TdbException, I18n.t('exception.passwords_do_not_match') unless params[:password] == params[:password_again]
    require_admin!(:gestion_admin)
    Admin.create(id: account.id, permissions: params[:permissions], passwd: Digest::MD5.hexdigest(params[:password]))
    redirect_to_url '/admins'
  end

  def update_admin
    require_admin!(:gestion_admin)
    admin = Admin.find_by(id: params[:id])
    fail TdbException, I18n.t('exception.account_is_not_admin', trigramme: '') unless admin
    admin.update(permissions: params[:permissions])
    redirect_to_url '/admins'
  end

  def delete_admin
    require_admin!(:gestion_admin)
    Admin.find(params[:id]).delete
    redirect_to_url '/admins'
  end

  def update_rights
    require_admin!(:gestion_admin)
    Right.transaction do
      Right.all.each do |right|
        right.update(
          Right.right_columns.map do |col|
            [col, (params["#{right.permissions}.#{col}"] == 'on')]
          end.to_h,
        )
      end
    end
    redirect_to_url '/admins'
  end

  def create_rights
    require_admin!(:gestion_admin)
    Right.create(nom: params[:name].strip, permissions: 1 + Right.maximum(:permissions).to_i)
    redirect_to_url '/admins'
  end

  def delete_rights
    require_admin!(:gestion_admin)
    permissions = params[:permissions].to_i
    fail TdbException, I18n.t('exception.rights_are_in_use') if Admin.exists?(permissions: permissions)
    Right.where(permissions: permissions).delete_all
    redirect_to_url '/admins'
  end
end
