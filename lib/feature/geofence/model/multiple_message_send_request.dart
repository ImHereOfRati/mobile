import 'package:json_annotation/json_annotation.dart';

import 'message_send_request.dart';
part 'multiple_message_send_request.g.dart';

@JsonSerializable()
class MultipleMessageSendRequest {
  final List<MessageSendRequest> requests;

  MultipleMessageSendRequest({required this.requests});

  factory MultipleMessageSendRequest.fromJson(Map<String, dynamic> json) =>
      _$MultipleMessageSendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MultipleMessageSendRequestToJson(this);
}
