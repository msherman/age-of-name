resource "aws_sns_topic" "pipeline-notifications" {
  name = "react-pipeline-notifications"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

data "aws_iam_policy_document" "notification_policy" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.pipeline-notifications.arn]
  }
}

resource "aws_sns_topic_policy" "pipeline-notifications-policy" {
  arn    = aws_sns_topic.pipeline-notifications.arn
  policy = data.aws_iam_policy_document.notification_policy.json
}

// we would typically define the sns topic notification, but terraform does not support setting up email notifications
// as they require a 2 step process of confirming the email address. I'll touch on how to do this in the README