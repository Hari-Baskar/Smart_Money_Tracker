import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:telephony/telephony.dart';
import '../../../core/utils/sms_scanner_new.dart';

class SmsDebugScreen extends HookConsumerWidget {
  const SmsDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanner = useMemoized(() => SmsScannerNew());
    final messages = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(false);
    final isMounted = useIsMounted();

    Future<void> refreshSms() async {
      isLoading.value = true;
      try {
        final List<SmsMessage> rawMessages = await scanner.getTodaysMessages();
        List<Map<String, dynamic>> processed = [];

        for (var msg in rawMessages) {
          final String address = msg.address ?? 'Unknown';
          final String body = msg.body ?? '';
          final DateTime? date = msg.date != null 
              ? DateTime.fromMillisecondsSinceEpoch(msg.date!) 
              : null;

          final parsed = scanner.parseMessage(body, address);
          
          processed.add({
            'address': address,
            'body': body,
            'date': date,
            'parsed': parsed,
          });
        }

        if (isMounted()) {
          messages.value = processed;
          isLoading.value = false;
        }
      } catch (e) {
        if (isMounted()) {
          isLoading.value = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Telephony Error: $e')),
          );
        }
      }
    }

    useEffect(() {
      refreshSms();
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Telephony SMS Debug', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshSms,
          ),
        ],
      ),
      body: isLoading.value 
        ? const Center(child: CircularProgressIndicator())
        : messages.value.isEmpty 
          ? const Center(child: Text('No messages found for today.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.value.length,
              itemBuilder: (context, index) {
                final item = messages.value[index];
                final parsed = item['parsed'];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Theme.of(context).colorScheme.surfaceVariant),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: parsed != null 
                          ? Theme.of(context).colorScheme.primaryContainer 
                          : Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        parsed != null ? Icons.account_balance_wallet : Icons.sms,
                        color: parsed != null 
                            ? Theme.of(context).colorScheme.onPrimaryContainer 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      item['address'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      parsed != null 
                        ? 'Detected: ₹${parsed['amount']}' 
                        : 'Tap to view details',
                      style: TextStyle(
                        color: parsed != null 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message Body:', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 11, 
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['body'], 
                              style: TextStyle(
                                fontSize: 14, 
                                height: 1.4,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Divider(height: 24, color: Theme.of(context).colorScheme.outlineVariant),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Time: ${item['date']?.toString().split('.').first ?? 'N/A'}', 
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (parsed != null)
                                  Chip(
                                    label: Text(
                                      parsed['merchant'], 
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
