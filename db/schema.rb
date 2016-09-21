# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160921130123) do

  create_table "admins", force: :cascade do |t|
    t.string   "username"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "polo_id"
  end

  add_index "admins", ["email"], name: "index_admins_on_email", unique: true
  add_index "admins", ["polo_id"], name: "index_admins_on_polo_id"
  add_index "admins", ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true

  create_table "categoria", force: :cascade do |t|
    t.string   "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categorie", force: :cascade do |t|
    t.string   "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "citta", force: :cascade do |t|
    t.string   "nome"
    t.string   "provincia"
    t.string   "regione"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "polo_id"
  end

  add_index "citta", ["polo_id"], name: "index_citta_on_polo_id"

  create_table "clienti", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "nome"
    t.string   "cognome"
    t.string   "cf"
    t.date     "data_nascita"
    t.string   "telefono"
    t.integer  "citta_id"
  end

  add_index "clienti", ["citta_id"], name: "index_clienti_on_citta_id"

  create_table "imprese", force: :cascade do |t|
    t.string   "nome"
    t.string   "telefono"
    t.string   "fax"
    t.string   "giorni_orari"
    t.string   "email"
    t.string   "sitoweb"
    t.string   "facebook"
    t.string   "descrizione"
    t.float    "lat"
    t.float    "lng"
    t.boolean  "verificato"
    t.boolean  "congelato"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "titolare_id"
    t.integer  "citta_id"
  end

  add_index "imprese", ["citta_id"], name: "index_imprese_on_citta_id"
  add_index "imprese", ["titolare_id"], name: "index_imprese_on_titolare_id"

  create_table "indirizzi", force: :cascade do |t|
    t.string   "via"
    t.integer  "ncivico"
    t.string   "cap"
    t.string   "quartiere"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "citta_id"
  end

  add_index "indirizzi", ["citta_id"], name: "index_indirizzi_on_citta_id"

  create_table "ordini", force: :cascade do |t|
    t.datetime "data"
    t.string   "stato"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "cliente_id"
    t.integer  "impresa_id"
  end

  add_index "ordini", ["cliente_id"], name: "index_ordini_on_cliente_id"
  add_index "ordini", ["impresa_id"], name: "index_ordini_on_impresa_id"

  create_table "poli", force: :cascade do |t|
    t.string   "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "admin_id"
  end

  add_index "poli", ["admin_id"], name: "index_poli_on_admin_id"

  create_table "prodotti", force: :cascade do |t|
    t.string   "nome"
    t.float    "prezzo"
    t.integer  "qta"
    t.string   "descrizione"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "sottocategoria", force: :cascade do |t|
    t.string   "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sottocategorie", force: :cascade do |t|
    t.string   "nome"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "categoria_id"
  end

  add_index "sottocategorie", ["categoria_id"], name: "index_sottocategorie_on_categoria_id"

  create_table "titolari", force: :cascade do |t|
    t.string   "piva"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "nome"
    t.string   "cognome"
    t.string   "cf"
    t.date     "data_nascita"
    t.string   "telefono"
    t.integer  "citta_id"
  end

  add_index "titolari", ["citta_id"], name: "index_titolari_on_citta_id"

  create_table "utenti", force: :cascade do |t|
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "actable_id"
    t.string   "actable_type"
  end

  add_index "utenti", ["email"], name: "index_utenti_on_email", unique: true
  add_index "utenti", ["reset_password_token"], name: "index_utenti_on_reset_password_token", unique: true

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id"

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",                         null: false
    t.integer  "item_id",                           null: false
    t.string   "event",                             null: false
    t.string   "whodunnit"
    t.text     "object",         limit: 1073741823
    t.datetime "created_at"
    t.text     "object_changes", limit: 1073741823
    t.integer  "transaction_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id"

end
