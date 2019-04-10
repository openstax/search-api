class Api::V0::DiagnosticsController < ApplicationController

  def exception
    raise "An exception for diagnostic purposes"
  end

end
