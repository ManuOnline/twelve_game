require_relative 'square'

class Game
  def initialize(window)
    @window = window
    @squares = []
    color_list = []
    [:red, :green, :blue].each do |color|
      12.times do 
        color_list.push color
      end
    end
    color_list.shuffle!
    (0..5).each do |row|
      (0..5).each do |column|
        index = row * 6 + column
        @squares.push Square.new(@window, column, row, color_list[index])
      end

      @right = Gosu::Sample.new('sounds/right.wav')
      @wrong = Gosu::Sample.new('sounds/wrong.wav')
    end
    @font = Gosu::Font.new(36)
    @win = false
    @win_image = Gosu::Image.new('images/win.png')
    @lose_image = Gosu::Image.new('images/lose.png')
    @play_image = Gosu::Image.new('images/play.png')
    @quit_image = Gosu::Image.new('images/quit.png')
  end

  def handle_mouse_down(x,y)
    row = (y.to_i - 20)/100
    column = (x.to_i - 20)/100
    @start_square = get_square(column, row)
  end

  def get_square(column, row)
    if column < 0 or column > 5 or row < 0 or row > 5
      return nil
    else
      return @squares[row * 6 + column]
    end
  end
  
  def handle_mouse_up(x, y)
    row = (y.to_i - 20) / 100
    column = (x.to_i - 20) / 100
    @end_square = get_square(column, row)
    if @start_square and @end_square
      move(@start_square, @end_square)
    end
    @start_square = nil
  end
  
  def move(square1, square2)
    return if square1.number == 0
    if square1.row == square2.row
      squares = squares_between_in_row(square1, square2)
    elsif square1.column == square2.column
      squares = squares_between_in_column(square1, square2)
    else
      return 
    end
    squares.reject!{|square| square.number == 0}
    if squares.count != 2 || squares[0].color != squares[1].color
    	@wrong.play
    	return
    end
    #return if squares.count != 2
    #return if squares[0].color != squares[1].color
    #valid move
    @right.play
    save
    color = squares[0].color
    number = squares[0].number + squares[1].number
    squares[0].clear
    squares[1].clear
    square2.set(color, number)
  end
  
  def squares_between_in_row(square1, square2)
    the_squares = []
    if square1.column < square2.column
      column_start, column_end = square1.column, square2.column
    else
      column_start, column_end = square2.column, square1.column 
    end
    (column_start .. column_end).each do |column|
      the_squares.push get_square(column, square1.row)
    end
    return the_squares
  end

  def squares_between_in_column(square1, square2)
    the_squares = []
    if square1.row < square2.row
      row_start, row_end = square1.row, square2.row
    else 
      row_start, row_end = square2.row, square1.row
    end
    (row_start .. row_end).each do |row|
      the_squares.push get_square(square1.column, row)
    end
    return the_squares
  end
  
  def handle_mouse_move(x, y)
    row = (y.to_i - 20) / 100
    column = (x.to_i - 20) / 100
    @current_square = get_square(column, row)
  end
  
  def move_is_legal?(square1, square2)
    return false if square1.number == 0
    if square1.row == square2.row
      squares = squares_between_in_row(square1, square2)
    elsif square1.column == square2.column
      squares = squares_between_in_column(square1, square2)
    else
      return false
    end
    squares.reject!{|square| square.number == 0}
    return false if squares.count != 2
    return false if squares[0].color != squares[1].color
    return true
  end
  
  def legal_move_for?(start_square)
    return false if start_square.number == 0
    @squares.each do |end_square|
      if move_is_legal?(start_square, end_square)
        return true
      end
    end
    return false
  end
  
  def game_over?
    @squares.each do |square|
      return false if legal_move_for?(square)
    end
    return true
  end
  
  def draw
      @squares.each do |square|
      square.draw
    end
    if game_over?
      c = Gosu::Color.argb(0x33000000)
      @window.draw_quad(0, 0, c, 640, 0, c, 640, 640, c, 0, 640, c, 4)

      count = @squares.count{|square| square.number == 12}
      if count == 3
            @win = true
        end
      @win_image.draw(0, 240, 5) if @win == true

      @lose_image.draw(0, 240, 5) if @win == false
      @play_image.draw(0, 320, 5)
      @quit_image.draw(0, 380, 5)
      return
    end
    return unless @start_square
    @start_square.highlight(:start)
    return unless @current_square && @current_square != @start_square
    if move_is_legal?(@start_square, @current_square)
      @current_square.highlight(:legal)
    else
      @current_square.highlight(:illegal)
    end
  end

  def save
    f = File.new("data/SaveGame.sav", "w+")
    Marshal.dump(@squares, f)
    f.close
  end

  def load
    file = File.open('data/SaveGame.sav')
    @squares = Marshal.load(file)
    file.close
  end
end
