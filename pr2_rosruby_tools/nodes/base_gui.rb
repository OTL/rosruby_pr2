#! /usr/bin/env ruby

#
# = sample of gui (Ruby/Tk)
# this sample needs geometry_msgs/Twist.
# The GUI publishes velocity as Twist.
#
# if you don't have the message files, try
#
# $ rosrun rosruby rosruby_genmsg.py geometry_msgs
#

require 'tk'
require 'ros'
ROS::load_manifest('pr2_rosruby_tools')
require 'geometry_msgs/Twist'


class VelPublisher
  def initialize(topic_name)
    @node = ROS::Node.new('/gui_test')
    @topic_name = topic_name
    @pub = @node.advertise(topic_name, Geometry_msgs::Twist)
    @msg = Geometry_msgs::Twist.new
    @is_on = false
  end

  def topic_name
    @topic_name
  end
  
  def shutdown
    @node.shutdown
    @thread.join
  end

  def topic_name=(name)
    @topic_name = name
    @pub.shutdown
    @pub = @node.advertise(@topic_name, Geometry_msgs::Twist)
    @topic_name
  end

  def start
    rate = ROS::Rate.new(10.0)
    @thread = Thread.new do
      while @node.ok?
        if @is_on
          @pub.publish(@msg)
        end
        rate.sleep
      end
    end
  end

  def stop
    @is_on = false
  end

  def publish(msg)
    @msg = msg
    @is_on = true
  end
end

class VelocityGUI
  def initialize(topic_name, max_linear_vel, max_angular_vel)
    @topic_name = topic_name
    @pub = VelPublisher.new(topic_name)
    @pub.start
    @linear_vel = max_linear_vel
    @angular_vel = max_angular_vel
  end

  def create

    # for access from proc objects
    pub = @pub
    linear_vel = @linear_vel
    angular_vel = @angular_vel
    topic_name = @topic_name

    TkButton.new {
      text "FORWARD"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        msg.linear.x = linear_vel
        pub.publish(msg)
      }
      width 10
      grid("row"=>0, "column"=>1)
      bind 'ButtonRelease', proc {pub.stop}
    }
    
    TkButton.new {
      text "LEFT"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        msg.linear.y = linear_vel
        pub.publish(msg)
      }
      width 10
      grid("row"=>1, "column"=>0)
      bind 'ButtonRelease', proc {pub.stop}
    }

    TkButton.new {
      text "RIGHT"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        msg.linear.y = -linear_vel
        pub.publish(msg)
      }
      width 10
      grid("row"=>1, "column"=>2)
      bind 'ButtonRelease', proc {pub.stop}
    }

    TkButton.new {
      text "Left Turn"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        msg.angular.z = angular_vel
        pub.publish(msg)
      }
      width 10
      grid("row"=>0, "column"=>0)
      bind 'ButtonRelease', proc {pub.stop}
    }

    TkButton.new {
      text "STOP"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        pub.publish(msg)
      }
      width 10
      grid("row"=>1, "column"=>1)
      bind 'ButtonRelease', proc {pub.stop}
    }

    TkButton.new {
      text "Right Turn"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        msg.angular.z = -angular_vel
        pub.publish(msg)
      }
      width 10
      grid("row"=>0, "column"=>2)
      bind 'ButtonRelease', proc {pub.stop}
    }


    TkButton.new {
      text "BACKWARD"
      bind 'ButtonPress', proc {
        msg = Geometry_msgs::Twist.new
        msg.linear.x = -linear_vel
        pub.publish(msg)
      }
      width 10
      grid("row"=>2, "column"=>1)
      bind 'ButtonRelease', proc {pub.stop}
    }

    TkScale.new {
      label 'linear vel(%)'
      from 0
      to 100
      orient 'horizontal'
      command do |val|
        linear_vel = val.to_f * 0.005
      end
      grid("row"=>3, "column"=>0)
    }.set(50)

    TkScale.new {
      label 'angular vel(%)'
      from 0
      to 100
      orient 'horizontal'
      command do |val|
        angular_vel = val.to_f * 0.01
      end
      grid("row"=>3, "column"=>1)
    }.set(50)

    TkButton.new {
      text "exit"
      command do
        pub.shutdown
        exit
      end
      width 5
      grid("row"=>3, "column"=>2)
    }

    TkLabel.new {
      text 'topic'
      grid("row"=>4, "column"=>0)
    }

    TkEntry.new {
      self.value = topic_name
      bind 'Return', proc {
        pub.topic_name = self.value
      }
      grid("row"=>4, "column"=>1, "columnspan"=>2, "sticky"=>"news")
    }

    Tk.root.bind ['Control-c', 'Control-c'], proc {
      pub.shutdown
      exit
    }
    Tk.root.title("base control GUI")
    self
  end

  def mainloop
    Tk.mainloop
  end
end

VelocityGUI.new('/base_controller/command', 1.0, 3.0).create.mainloop
