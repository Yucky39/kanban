class BoardsController < ApplicationController
  before_action :require_login

  # GET /
  def index
    @boards = Board.where(user_id: current_user_id.to_i).order("id").to_a
  end

  # GET /boards/1
  def show
    @board = owned_board(params[:id])
    cards = Card.where(board_id: @board.id).order("position, id").to_a
    @todo = cards.select { |c| c.status == "todo" }
    @doing = cards.select { |c| c.status == "doing" }
    @done = cards.select { |c| c.status == "done" }
  end

  # POST /boards
  def create
    board = Board.new(name: params[:name].to_s.strip, user_id: current_user_id.to_i)
    if board.save
      flash[:notice] = "Board created."
      redirect_to board_path(board), status: :see_other
    else
      flash[:alert] = "Name " + board.errors.full_messages.join(", ")
      redirect_to "/", status: :see_other
    end
  end

  # DELETE /boards/1
  def destroy
    board = owned_board(params[:id])
    Card.where(board_id: board.id).delete_all
    board.destroy
    flash[:notice] = "Board deleted."
    redirect_to "/", status: :see_other
  end

  private

  def owned_board(id)
    Board.where(user_id: current_user_id.to_i).find(id)
  end
end
