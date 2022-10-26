using System.Collections.Generic;
using System;

namespace yc_scale_2022.Models
{
        public class TrackerQueue
        {
            public string key { get; set; }
        }

        public class TrackerPayloadModel
        {
            public TrackerPayloadModel()
            {
            this.queue = new TrackerQueue();
            }
            public string description { get; set; }
            public string summary { get; set; }
            public TrackerQueue queue { get; set; }
            public string osnovnaaEmocia { get; set; }
            public string assignee { get; set; }
            public string tags { get; set; }
            public int boards { get; set; }
        }



    public class TrackerResponseModel
    {
        public string self { get; set; }
        public string id { get; set; }
        public string key { get; set; }
        public int version { get; set; }
        public string summary { get; set; }        
        public string statusStartTime { get; set; }
        public UpdatedBy updatedBy { get; set; }
        public List<Board> boards { get; set; }
        public Type type { get; set; }
        public Priority priority { get; set; }
        public List<string> tags { get; set; }
        public string createdAt { get; set; }
        public CreatedBy createdBy { get; set; }
        public int commentWithoutExternalMessageCount { get; set; }
        public List<string> osnovnaaEmocia { get; set; }
        public int votes { get; set; }
        public int commentWithExternalMessageCount { get; set; }
        public Assignee assignee { get; set; }
        public Queue queue { get; set; }
        public string updatedAt { get; set; }
        public Status status { get; set; }
        public bool favorite { get; set; }
    }



    public class Assignee
    {
        public string self { get; set; }
        public string id { get; set; }
        public string display { get; set; }
    }

    public class Board
    {
        public int id { get; set; }
    }

    public class CreatedBy
    {
        public string self { get; set; }
        public string id { get; set; }
        public string display { get; set; }
    }

    public class Priority
    {
        public string self { get; set; }
        public string id { get; set; }
        public string key { get; set; }
        public string display { get; set; }
    }

    public class Queue
    {
        public string self { get; set; }
        public string id { get; set; }
        public string key { get; set; }
        public string display { get; set; }
    }

   
    public class Status
    {
        public string self { get; set; }
        public string id { get; set; }
        public string key { get; set; }
        public string display { get; set; }
    }

    public class Type
    {
        public string self { get; set; }
        public string id { get; set; }
        public string key { get; set; }
        public string display { get; set; }
    }

    public class UpdatedBy
    {
        public string self { get; set; }
        public string id { get; set; }
        public string display { get; set; }
    }


}
