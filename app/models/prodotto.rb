=begin
Copyright 2017 Alessandro Profiti, Gabriele Restuccia, Lorenzo Ricelli.

This file is part of PagoChiNonPaga.

PagoChiNonPaga is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PagoChiNonPaga is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
=end

class Prodotto < ActiveRecord::Base
  has_paper_trail
  # Associazioni
  belongs_to :impresa
  has_and_belongs_to_many :ordini

  # Validations necessarie per la registrazione
  validates :nome, :prezzo, :qta, :descrizione, :impresa_id, presence: true
  validates_numericality_of :qta, :greater_than_or_equal_to => 0
  validates_numericality_of :prezzo, :greater_than_or_equal_to => 0, only_float: true
  validate :unique_entry #custom validation
  validates_format_of :nome, :with => /\A([a-zA-Z '\-0-9òàùèé]+)$\z/, :message => "Sono permesse solo lettere da a-z, numeri 0-9, spazi, apostrofi, trattini."

  # Uploaer Immagini
  mount_uploader :image, ImageUploader
  validate :file_size

  def file_size
    max_file_size_mb= 5
    if self.image?
      if image.file.size.to_f/(1000*1000) > max_file_size_mb
        errors.add(:image, "La dimensione dell'immagine (in megabyte) è troppo grande.")
      end
    end
  end

  # Custom validation per controllare unicita tra piu campi senza case_sensitive
  def unique_entry
    matched_entry = Prodotto.where(['LOWER(nome) = LOWER(?) AND impresa_id=? AND eliminato=?', self.nome, self.impresa_id, false]).first #il '?' e' un parametro per SQL passato da self.campo
    errors.add(:base, 'Prodotto già presente.') if matched_entry && (matched_entry.id != self.id) #se non sono io stesso allora c'e' un errore
  end

  # Necessario per mostrare il nome dell'Entita in RailsAdmin
  def name
    self.nome
  end

  def checkDisponibilita(qta,carrello)
    prodotto_carrello = carrello.cart_items.where(item_id: self.id).first
    qta_carrello=0
    if prodotto_carrello != nil
      qta_carrello = prodotto_carrello.quantity
    end
    self.qta >= (qta + qta_carrello) && qta > 0
  end

  def  checkDisponibilitaOrdine(qta_carrello)
     self.qta >= qta_carrello
  end

  def getQuantita
    self.qta
  end

  def setQuantita(qta)
    nuova_qta = self.qta - qta
    self.update_attribute('qta', nuova_qta)
  end

  def clearQuantita
    self.update_attribute('qta', 0)
  end


  def setEliminato(eliminato)
    self.update_attribute('eliminato', eliminato)
  end

end
