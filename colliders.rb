class Colliders
  attr_reader :top_collision
  attr_reader :bottom_collision
  attr_reader :left_collision
  attr_reader :right_collision

  def initialize(collider_name, buffer, centre_and_top_gap, centre_and_bottom_gap, centre_and_left_gap, centre_and_right_gap)
    # collider_name is the name (a string) given to the collider layer in Tiled
    # rest of arguments are the size of the gaps required between different parts of a sprite and the colliders
    @collider_name = collider_name
    @buffer = buffer
    @centre_and_top_gap = centre_and_top_gap
    @centre_and_bottom_gap = centre_and_bottom_gap
    @centre_and_left_gap = centre_and_left_gap
    @centre_and_right_gap = centre_and_right_gap
  end

  def calculate_lines
    # loads the json map file exported from Tiled, with all its collider layers
    file = File.read("map.json")
    data_hash = JSON.parse(file)
    # locates the array named "objects" within the json file and assigns it. "objects" in the json file contains the coordinates for every point in the colliders
    data_hash["layers"].each do |x|
      if x["name"] == "#{@collider_name}"
        @data_from_tiled = x["objects"]
      end
    end
    # the coordinates for each point within the json file are relative and not actual. We'll need to adjust them using the origin of each collider

    # first we set up an array to collect the points once we've adjusted them
    @colliders = []
    # this is a temp storage for each point. We'll use it later to pass each point seperately to @colliders
    @temp_collider_storage = []
    # then we go into the data from the json file and retrieve and assign the origin of each collider
    @data_from_tiled.each do |data|
      polyline_x_origin = data["x"]
      polyline_y_origin = data["y"]
      # then we take every coordinate for each point and adjust it relative to the collider's origin to get its 'true' value
      data["polyline"].each do |polyline_point|
        adjusted_polyline_x = polyline_point["x"] + polyline_x_origin
        adjusted_polyline_y = polyline_point["y"] + polyline_y_origin
        # then we pass the adjusted coordinates of each point to the temp storage array
        @temp_collider_storage.push ({ x: adjusted_polyline_x, y: adjusted_polyline_y })
      end
      # then we pass the adjusted coordinates to @colliders. Doing it like this ensures that each point is passed one at a time, as seperate objects
      @colliders.push @temp_collider_storage
      # this resets the temp storage array so it can be used to collect the next point's adjusted coordinates
      @temp_collider_storage = []
    end

    # next, we set up an array to pair-up the points of each line that makes up every collider.
    # Each line (like any line) will have two points ie coordinates. The end coordinate of one line will be the starting coordinate of the next line in the collider
    @lines = []
    # so we take each point...
    @colliders.each do |point|
      # ...and access each of its coordinates, along with each coordinate's array index (its numercal location in the array)
      point.each_with_index do |coordinate, i|
        # if the coordinate doesn't have a following coordinate, nothing happens.
        # Otherwise the coordinate is pushed with its ajacent coordinate into @lines (each pair of coordinates, or points, now represents a line in its collider)
        if point[i + 1].nil?
          0
        else
          next_coordinate = point[i + 1]
          @lines.push [coordinate, next_coordinate]
        end
      end
    end
    # Now we want to work out the 'range' of each line so we can find out if the player will bump into it
    # First set up an array to collect the ranges for each line
    @line_ranges = []
    # Then for each line we extract the two x values and sort them from low to high. Same with y values. Then push to @lines_ranges.
    @lines.each do |line|
      x_values_sorted = [line[0][:x], line[1][:x]].sort!
      y_values_sorted = [line[0][:y], line[1][:y]].sort!
      @line_ranges.push ({ x_range: x_values_sorted, y_range: y_values_sorted })
    end
    # @lines_ranges can now be passed to whatever entity needs to know colliders
    @line_ranges
  end

  def top_collision_check(x, y, speed)
    @x = x
    @y = y
    @speed = speed
    player_top_and_buffer = y + @centre_and_top_gap + @buffer
    player_right = @x + 6
    player_left = @x - 6
    # at the start of every check, we assume there is no collision
    @top_collision = false
    # Then we look to see if we are within the x values in all the lines (colliders) we have.
    @line_ranges.each do |range|
      x_left = range[:x_range][0]
      x_right = range[:x_range][1]
      y_top = range[:y_range][0]
      # if we are within x range, then check to see we are below the line (as that's the only way we can top collide with it)
      # I've used '&& x_left != x_right' to exclude vertical lines
      if (player_left >= x_left) && (player_left <= x_right) && player_top_and_buffer > y_top && x_left != x_right
        if Gosu.distance(@x, player_top_and_buffer - @speed, @x, y_top) <= @buffer
          @top_collision = true
        end
      end
      if (player_right >= x_left) && (player_right <= x_right) && player_top_and_buffer > y_top && x_left != x_right
        if Gosu.distance(@x, player_top_and_buffer - @speed, @x, y_top) <= @buffer
          @top_collision = true
        end
      end
    end
    @top_collision
  end

  def bottom_collision_check(x, y, speed)
    @x = x
    @y = y
    @speed = speed
    player_bottom_and_buffer = y + @centre_and_bottom_gap - @buffer
    player_right = @x + 6
    player_left = @x - 6
    @bottom_collision = false
    @line_ranges.each do |range|
      x_left = range[:x_range][0]
      x_right = range[:x_range][1]
      y_bottom = range[:y_range][0]
      if (player_left >= x_left) && (player_left <= x_right) && player_bottom_and_buffer < y_bottom && x_left != x_right
        if Gosu.distance(@x, player_bottom_and_buffer + @speed, @x, y_bottom) <= @buffer
          @bottom_collision = true
        end
      end
      if (player_right >= x_left) && (player_right <= x_right) && player_bottom_and_buffer < y_bottom && x_left != x_right
        if Gosu.distance(@x, player_bottom_and_buffer + @speed, @x, y_bottom) <= @buffer
          @bottom_collision = true
        end
      end

    end

  end

  def left_collision_check(x, y, speed)
    @x = x
    @y = y
    @speed = speed
    player_top = @y + @centre_and_top_gap
    player_bottom = @y + @centre_and_bottom_gap
    player_right = @x + @centre_and_right_gap
    player_left_and_buffer = @x - @centre_and_left_gap + @buffer
    @left_collision = false
    @line_ranges.each do |range|
      y_top = range[:y_range][0]
      y_bottom = range[:y_range][1]
      x_left = range[:x_range][0]
      if (player_top >= y_top) && (player_top <= y_bottom) && player_left_and_buffer > x_left && y_top != y_bottom
        if Gosu.distance(player_left_and_buffer - @speed, @y, x_left, @y) <= @buffer
          @left_collision = true
        end
      end
      if (player_bottom >= y_top) && (player_bottom <= y_bottom) && player_left_and_buffer > x_left && y_top != y_bottom
        if Gosu.distance(player_left_and_buffer - @speed, @y, x_left, @y) <= @buffer
          @left_collision = true
        end
      end
    end
  end

  def right_collision_check(x, y, speed)
    @x = x
    @y = y
    @speed = speed
    player_top = @y + @centre_and_top_gap
    player_bottom = @y + @centre_and_bottom_gap
    player_right_and_buffer = @x + @centre_and_right_gap - @buffer
    @right_collision = false
    @line_ranges.each do |range|
      y_top = range[:y_range][0]
      y_bottom = range[:y_range][1]
      x_right = range[:x_range][1]
      if (player_top >= y_top) && (player_top <= y_bottom) && player_right_and_buffer < x_right && y_top != y_bottom
        if Gosu.distance(player_right_and_buffer + @speed, @y, x_right, @y) <= @buffer
          @right_collision = true
        end
      end
      if (player_bottom >= y_top) && (player_bottom <= y_bottom) && player_right_and_buffer < x_right && y_top != y_bottom
        if Gosu.distance(player_right_and_buffer + @speed, @y, x_right, @y) <= @buffer
          @right_collision = true
        end
      end
    end

  end

end