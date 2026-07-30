import 'package:flutter/material.dart';

/// Where the share flow was entered from. Decides where [closeShareFlow]
/// returns the user to.
enum ShareTicketEntry { journalContent, journalComplete }

/// Route name applied to every screen pushed inside the share flow
/// (poster picker + share ticket). Used by [closeShareFlow] to pop back
/// past all in-flow routes regardless of how many sit on the stack.
const String kShareFlowRouteName = 'share_flow';

/// Closes the share flow and returns the user to the right place based on
/// where they entered:
///  - [ShareTicketEntry.journalComplete] (just-saved journal): back to home.
///  - [ShareTicketEntry.journalContent] (sharing an existing journal): back
///    to the journal content screen below the share flow.
void closeShareFlow(BuildContext context, ShareTicketEntry entry) {
  final nav = Navigator.of(context);
  switch (entry) {
    case ShareTicketEntry.journalComplete:
      nav.popUntil((route) => route.isFirst);
    case ShareTicketEntry.journalContent:
      nav.popUntil((route) => route.settings.name != kShareFlowRouteName);
  }
}
