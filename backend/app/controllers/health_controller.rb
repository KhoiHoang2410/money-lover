class HealthController < ApplicationController
  Status = Struct.new(:status)

  def show
    render json: StatusRepresenter.new(Status.new("ok")).to_json
  end
end
