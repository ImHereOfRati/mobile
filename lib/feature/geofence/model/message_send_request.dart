import 'package:json_annotation/json_annotation.dart';

part 'message_send_request.g.dart';

@JsonSerializable()
class MessageSendRequest {
  final String receiverNumber;
  final String location;

  factory MessageSendRequest.fromJson(Map<String, dynamic> json) =>
      _$MessageSendRequestFromJson(json);

  MessageSendRequest({required this.receiverNumber, required this.location});
  Map<String, dynamic> toJson() => _$MessageSendRequestToJson(this);
}
