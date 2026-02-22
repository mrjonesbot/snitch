module Snitch
  class SnitchesController < ActionController::Base
    layout "snitch/application"

    def index
      @tab = params[:tab] || "open"
      @events = case @tab
                when "open" then Snitch::Event.open.order(last_occurred_at: :desc)
                when "closed" then Snitch::Event.closed.order(updated_at: :desc)
                when "ignored" then Snitch::Event.ignored.order(updated_at: :desc)
                else Snitch::Event.open.order(last_occurred_at: :desc)
                end
      @counts = {
        open: Snitch::Event.open.count,
        closed: Snitch::Event.closed.count,
        ignored: Snitch::Event.ignored.count
      }
    end

    def show
      @event = Snitch::Event.find(params[:id])
    end

    def update
      @event = Snitch::Event.find(params[:id])
      @event.update!(status: params[:status])

      if params[:redirect_to] == "show"
        redirect_to snitch_path(@event), notice: "Snitch updated."
      else
        redirect_to snitches_path(tab: params[:tab] || @event.status), notice: "Snitch updated."
      end
    end
  end
end
