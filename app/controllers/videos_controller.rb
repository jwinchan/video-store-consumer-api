class VideosController < ApplicationController
  before_action :require_video, only: [:show]

  def index
    if params[:query]
      data = VideoWrapper.search(params[:query])
    else
      data = Video.all
    end

    render status: :ok, json: data
  end

  def show
    render(
      status: :ok,
      json: @video.as_json(
        only: [:title, :overview, :release_date, :inventory],
        methods: [:available_inventory]
        )
      )
  end

  # Adds a video from the external API to the library
  def add_to_library
    if params[:id]
      begin
        video = VideoWrapper.get_movie(params[:id])
        unless params[:inventory].to_i > 0
          render_error("Invalid inventory given", :bad_request)
        end
        video.inventory = params[:inventory]
      rescue ArgumentError
        render_error("Unspecified API error", :bad_request)
        return
      end

      if video # If the movie was found
        if video.save # If the video saves
          render json: {
            ok: true,
            id: video.id
          }, status: :created
          return
        else # If the video doesn't save
          render_error(video.errors.messages, :bad_request)
          return
        end
      else # If the movie wasn't found
        render_error("Movie was not found from external API", :not_found)
        return
      end
    else # If no ID given
      render_error("No ID given", :bad_request)
      return
    end
  end

  private

  def render_error(error, status)
    render json: {
      ok: false,
      errors: error
    }, status: status
  end

  def require_video
    @video = Video.find_by(title: params[:title])
    unless @video
      render status: :not_found, json: { errors: { title: ["No video with title #{params["title"]}"] } }
    end
  end

  def video_params
    return params.permit(:title, :overview, :release_date, :inventory)
  end
end
