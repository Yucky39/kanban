class CardsController < ApplicationController
  before_action :require_login

  # POST /boards/1/cards
  def create
    board = owned_board(params[:board_id])
    card = Card.new(title: params[:title].to_s.strip, description: params[:description].to_s,
                    status: "todo", position: next_position(board.id, "todo"), board_id: board.id)
    if card.save
      flash[:notice] = "Card added."
    else
      flash[:alert] = "Card " + card.errors.full_messages.join(", ")
    end
    redirect_to board_path(board), status: :see_other
  end

  # PATCH /cards/1/left, /cards/1/right
  def move_left
    shift(-1)
  end

  def move_right
    shift(1)
  end

  # DELETE /cards/1
  def destroy
    card = owned_card(params[:id])
    board_id = card.board_id
    card.destroy
    flash[:notice] = "Card deleted."
    redirect_to board_path(board_id), status: :see_other
  end

  private

  def shift(step)
    card = owned_card(params[:id])
    index = status_index(card.status.to_s)
    target = index + step
    if target >= 0 && target < Card::STATUSES.size
      status = Card::STATUSES[target]
      card.status = status
      card.position = next_position(card.board_id, status)
      card.save
    end
    redirect_to board_path(card.board_id), status: :see_other
  end

  # 0 for "todo", 1 for "doing", 2 for "done" (0 for anything unexpected). A loop
  # over String comparisons: Array#index with a column value does not compile here.
  def status_index(status)
    i = 0
    while i < Card::STATUSES.size
      return i if Card::STATUSES[i] == status
      i += 1
    end
    0
  end

  def next_position(board_id, status)
    last = Card.where(board_id: board_id, status: status).order("position DESC").first
    last.nil? ? 1 : last.position + 1
  end

  # A card is reachable only through a board that belongs to the signed-in user.
  def owned_card(id)
    card = Card.find(id)
    Board.where(user_id: current_user_id.to_i).find(card.board_id)
    card
  end

  def owned_board(id)
    Board.where(user_id: current_user_id.to_i).find(id)
  end
end
