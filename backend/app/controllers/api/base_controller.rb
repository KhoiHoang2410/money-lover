module Api
  # Base for every authenticated, tenant-scoped resource controller (issues
  # 13–20). Inherits JSON-only handling + error rendering from
  # ApplicationController and adds `current_user` + the tenant authorization
  # helpers from Tenancy.
  class BaseController < ApplicationController
    include Tenancy
  end
end
