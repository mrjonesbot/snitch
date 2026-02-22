Rails.application.routes.draw do
  mount Snitch::Engine, at: "/snitches"
  root to: redirect("/snitches")
end
