Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "view/:body/:grid_id/:direct/:radius", to: "earth#view"  
  get "view/:body/:grid_id/:direct", to: "earth#view"  
  get "view/:body/:grid_id", to: "earth#view"  
  get "view/:body", to: "earth#view"  
  get "view", to: "earth#view"

  get "troops/:grid_id/:radius", to: "earth#troops"
end
