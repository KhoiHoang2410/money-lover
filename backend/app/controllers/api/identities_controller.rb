module Api
  # The current user's login methods. Serves as the representative tenant-scoped
  # resource that exercises the authorization foundation (issue 05); the full
  # domain resources build on the same `load_owned!` helper in issues 13–20.
  class IdentitiesController < BaseController
    def show
      identity = load_owned!(:identities, params[:id])
      render json: IdentityRepresenter.new(identity).to_json
    end
  end
end
