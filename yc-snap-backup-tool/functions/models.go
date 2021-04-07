package main

import (
	"time"
)

type EventMetadata struct {
	EventId   string    `json:"event_id"`
	EventType string    `json:"event_type"`
	CreatedAt time.Time `json:"created_at"`
	CloudId   string    `json:"cloud_id"`
	FolderId  string    `json:"folder_id"`
}
type Attributes struct {
	ApproximateFirstReceiveTimestamp string `json:"ApproximateFirstReceiveTimestamp"`
	ApproximateReceiveCount          string `json:"ApproximateReceiveCount"`
	SentTimestamp                    string `json:"SentTimestamp"`
}
type MessageAttributes struct {
}

type Message struct {
	MessageId              string            `json:"message_id"`
	Md5OfBody              string            `json:"md5_of_body"`
	Body                   string            `json:"body"`
	Attributes             Attributes        `json:"attributes"`
	MessageAttributes      MessageAttributes `json:"message_attributes"`
	Md5OfMessageAttributes string            `json:"md5_of_message_attributes"`
}
type Details struct {
	QueueId string  `json:"queue_id"`
	Message Message `json:"message"`
}

type MessageQueueMessage struct {
	EventMetadata EventMetadata `json:"event_metadata"`
	Details       Details       `json:"details"`
}

type MessageQueueEvent struct {
	Messages []MessageQueueMessage `json:"messages"`
}

type CreateSnapshotParams struct {
	FolderId string `json:"folderId"`
	DiskId   string `json:"diskId"`
}

type Response struct {
	StatusCode int         `json:"statusCode"`
	Body       interface{} `json:"body"`
}
