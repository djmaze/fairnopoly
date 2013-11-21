# Responsible for buyer's confirmations and sales notifications.
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#

class TransactionMailer < ActionMailer::Base
	helper TransactionHelper
	helper TransactionMailerHelper

  default from: $email_addresses['ArticleMailer']['default_from']

  def buyer_notification transaction
  	@transaction 	= transaction
  	@seller 			= transaction.article_seller
  	@buyer 				= transaction.buyer

    mail(	to: 			@buyer.email,
    			subject: 	"[Fairnopoly] " + t('transaction.notifications.buyer.buyer_subject') + " (#{transaction.article_title})") do |format|
          format.text
    end
  end

  def seller_notification transaction
  	@transaction 	= transaction
  	@seller 			= transaction.article_seller
  	@buyer 				= transaction.buyer

  	subj = "[Fairnopoly] " + t('transaction.notifications.seller.seller_subject') + " (#{transaction.article_title})"

  	if transaction.article.has_friendly_percent?
  	   @donated_ngo = transaction.article.donated_ngo
       subj += ( t('transaction.notifications.seller.with_donation_to') + @donated_ngo.nickname )
    end

    mail( to: @seller.email, subject: subj )  do |format|
            format.text
      end
  end
end