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

  private

  def simulator_parameters
    params.require(:simulator).permit(:email, :name, :source, :version)
  end
end
