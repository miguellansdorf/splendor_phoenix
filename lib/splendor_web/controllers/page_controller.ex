defmodule SplendorWeb.PageController do
  use SplendorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
