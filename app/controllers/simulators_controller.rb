class SimulatorsController < AuthenticatedController
  expose(:simulators) do
    if params[:search]
      Simulator.search(params[:search]).order("#{sort_column} #{sort_direction}")
        .page(params[:page])
    else
      Simulator.order("#{sort_column} #{sort_direction}").page(params[:page])
    end
  end
  expose(:simulator, attributes: :simulator_parameters)

  def create
    simulator.save
    respond_with(simulator)
  end

  def update
    simulator.save
    respond_with(simulator)
  end

  def destroy
    simulator.destroy
    respond_with(simulator)
  end

  def index
    @default_search_column = "Name"
  end

  def download_zip
    path = "./public/uploads/simulator/source/#{simulator.id}/"
    if Dir.exist?(path)
      Dir.foreach(path) {|x| send_file (path + x) unless x == "." || x == ".."}
    else
      flash[:alert] = "Simulator zip not found."
      redirect_to :back
    end
  end

  private

  def simulator_parameters
    params.require(:simulator).permit(:email, :name, :source, :version)
  end
end
