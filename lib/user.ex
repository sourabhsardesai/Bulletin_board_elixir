defmodule User do


  defp decleration(name) do      # mapping of variables which are used in User module, these variables are only accessed in User module and not by Topic manager
    %{ myname: name,
       mail_box: []
     }
  end

  def start(name) do
    pid = spawn( User,:process, [decleration(name)])          # a status is spawn  by the name of "status" and the initial variables are passed inside the status
     case :global.register_name(name,pid) do    # global.register registers the name of participant with the pid
       :yes -> pid                                 # if yes then the respective pid is returned
       :no  -> :error                                # if no respective error is returned
    end

  end


  # def subscribe(u,t) do
  #   :addr = :global.whereis_name(u)
  #   send(:addr, {:input, :subscription, :addr,t})



  # end

# As per advised in the task, the subscribe api for the user to subscribe a particular topic,So as to receive the messages from respective topic. This Api takes user name and topic
  def subscribe(user,topic) do
    IO.puts("User name #{user} and respective topic is #{topic}")
    send(:global.whereis_name(user), {:input, :subscription, :global.whereis_name(user),topic})  # sends message to Process in the name of subscription with global registered user and topic

  end
# As per advised in the task, The unsubscribe api for the user to unsubscribe or disable the topic, So as to stop receiving message from that topic. This api takes user and topic.
  def unsubscribe(user,topic) do
    IO.puts("User name #{user} and respective topic is #{topic}")
        send(:global.whereis_name(user), {:input, :unsubscription, :global.whereis_name(user),topic}) # sends message to Process in the name of unsubscription with global registered user and topic
end

# As per advised in the task, The fetch_news api for the user to fetch the messages on the topic the user is subscribed
def fetch_news(user) do

  send(:global.whereis_name(user),{:input,:fetch_news}) # sends message to process to access the mailbox to get the messages for respective topic
end

# As per advised in the task, The post api for the user is used to post the message from one node to a specific topic
def post(user,topic,message_packet) do
  IO.puts("User name #{user} and respective topic is #{topic} along with message i.e #{message_packet}")

  send(:global.whereis_name(user), {:input, :post, :global.whereis_name(user),:global.whereis_name(topic), message_packet}) # Send the message to the process under :post with user name , topic and respective message
end



# All the above api are called by the users and these apis are processed in the below process function

  def process(status) do
    status = receive do                       # the messages passed from the apis are received in the status and all the current stauts is updated within


      {:input, :subscription, user,topic} ->           # handles the message coming from the Subcription api

          case :global.whereis_name(topic)  do            # uses case statement
          :undefined ->  pid =TopicManager.start(topic)    # passes the topic to the TaskManager module
              send(pid,{:subscribe,user})                  # sends the message to the TaskManager module
               status
               _->

               #_ ->
              pidt= :global.whereis_name(topic)
              send(pidt,{:subscribe,user})
              status
             end

        {:input, :unsubscription, user,topic} ->               # handles the message coming from the unsubcription api
           case :global.whereis_name(topic)  do                 # uses case statement
             :undefined -> IO.puts("error in input")
               _ ->
               pid= :global.whereis_name(topic)
                send(pid,{:unsubscribe,user})                        # sends the message to the Taskmanager module
               status
             end

        {:input, :post, user, topic, message_packet} ->               # handles the message coming from post api to
           send(topic,{:post, user,topic, message_packet})            # sends the message to Taskmanager to handle and seend the message further
           status

        {:mailbox,topic,message_packet} ->
             status= update_in(status,[:mail_box],fn(list) -> [{topic,message_packet}|list]  # updates the mailbox with the new topic and message
               end
             )
             status
      # As advised this api is used to retreive the message from the mail box for the respective subscribed topics by the user.
         {:input,:fetch_news} ->
          IO.puts("message from " <> inspect(status.mail_box))

      end
        process(status)
  end





end

defmodule TopicManager do                        # TOpic Manager is seperate Module implemented to handle topic subscriptions and handling messages



defp decleration(topic_name) do         # Internal variables declerations
    %{
      topic_name: topic_name,
      message_packet: [],
      sub_user: []
  }
  end
  def start(topic_name) do                      # User.start calls the function which spawns the seperate processes for users
    pid = spawn( TopicManager,:process,[decleration(topic_name)] )
    case :global.register_name(topic_name,pid) do
      :yes -> pid
      :no  -> :error
    end
  end
  def process(task_status) do
         task_status= receive do
      {:subscribe,user} ->                                   # receives the message from the User module
        task_status= update_in(task_status,[:sub_user],fn(list) ->  [{user}|list]   # the subscribers name is then updated on the list which can be accessed by other process
           end
        )
        task_status
        {:unsubscribe,user} ->        # receives the message from the User module to unsubscribe the user
          task_status= update_in(task_status,[:sub_user],fn(list) -> List.delete(list,{user})  # deletes the user
            end
            )
            task_status
        {:post, user,topic,message_packet} ->   # receives the message from the user module when post api is called by the user
          task_status= update_in(task_status,[:message_packet],fn(list) -> [{user,topic,message_packet}|list]      # message for respective topic is updated on the list
            end
          )
          post_message(task_status.sub_user,topic,message_packet)
          task_status
    end
    process(task_status)
  end

  def post_message([],_,_), do: []

  def post_message([{user}|rest],topic,message_packet) do
    send(user,{:mailbox,topic,message_packet})
    post_message(rest,topic,message_packet)
  end
end


# to be executed from the terminals
#bob=User.start("bob")
#User.subscribe("bob","computing")

# Alice= User.start("Alice")
#User.subscribe("Alice,"computing")

#User.post("bob","computing","hello world")

#User.fetch_news("Alice")
