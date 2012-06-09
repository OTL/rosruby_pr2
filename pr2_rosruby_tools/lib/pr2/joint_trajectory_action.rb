require 'ros'

ROS::load_manifest('rosruby_pr2')
require 'pr2_controllers_msgs/JointTrajectoryAction'
require 'trajectory_msgs/JointTrajectoryPoint'
require 'actionlib/simple_action_client'

class TrajectoryProxy

  include Pr2_controllers_msgs
  include Trajectory_msgs

  def initialize(node, action_name)
    @action_name = "#{action_name}/joint_trajectory_action"
    @joint_names = node.get_param("#{action_name}/joints")
    @client = Actionlib::SimpleActionClient.new(node,
                                                @action_name,
                                                JointTrajectoryAction)
  end

  def joint_names
    @joint_names
  end

  def dof
    @joint_names.length
  end

  # wait=false, start_stamp=nil
  def send_trajectory(poses, times, options={})
    if poses.length != times.length
      raise 'poses and times length not mutch'
    end
    poses.each do |pose|
      if pose.length != @joint_names.length
        raise "pose length (#{pose.length}) and joint_names (#{@joint_names.length}) not mutch"
      end
    end

    @client.wait_for_server(10.0)

    goal = JointTrajectoryGoal.new
    goal.trajectory.joint_names = @joint_names
    if options[:start_stamp]
      goal.trajectory.header.stamp = options[:start_stamp]
    else
      goal.trajectory.header.stamp = ROS::Time.now + ROS::Duration.new(0.1)
    end

    poses.zip(times) do |pose, time|
      p1 = JointTrajectoryPoint.new
      p1.positions = pose
      p1.velocities = Array.new(dof, 0.0)
      p1.accelerations = Array.new(dof, 0.0)
      p1.time_from_start = ROS::Duration.new(time)
      goal.trajectory.points << p1
    end

    @client.send_goal(goal)
    if options[:wait]
      wait_result
    end
  end

  def wait_result
    @client.wait_for_result
  end
end

if __FILE__ == $0
  node = ROS::Node.new('/test_joint')
  tp = TrajectoryProxy.new(node, '/l_arm_controller')
  tp.send_trajectory([[1.0,0.0,0.0,0.0,0.0,0.0,0.0],
                      [0.0,0.0,1.0,0.0,1.0,0.0,1.0],
                      [0.0,0.0,0.0,0.0,0.0,0.0,1.0]],
                     [0.1, 2.0, 5.0], :wait => true)
end
