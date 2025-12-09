import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/models/donation.dart';

import 'package:foodbridge/providers/donations_notifier.dart';
import 'package:foodbridge/providers/donations_state.dart';
import 'package:foodbridge/providers/auth_notifier.dart';
import 'package:foodbridge/screens/chat_screen.dart';
import 'package:foodbridge/utils/constants.dart';

class DonationRequestsScreen extends ConsumerWidget{
  const DonationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final authState = ref.watch(authProvider);
    final donationsState = ref.watch(donationsProvider);
    final userRole = authState.user?.role ?? roleInNeed;

  if(donationsState.activeDonations.isEmpty && !donationsState.isLoading && donationsState.error == null){
  WidgetsBinding.instance.addPostFrameCallback((_){
  ref.read(donationsProvider.notifier).fetchDonations();
  });
  }

  ref.listen<DonationsState>(donationsProvider,(previous, current){
    if(current.error != null && !current.isLoading){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failure: ${current.error}')),
      );
    }
  });

  return Scaffold(
    appBar: AppBar(
      title: Text(userRole == roleInNeed ? 'Requests(recipient)' : 'Incoming requests(donor)'),    
    ),
    body: _buildBody(donationsState, userRole, ref),
  );
  }

  Widget _buildBody(DonationsState state, String userRole, WidgetRef ref){
    if(state.isLoading){
      return const Center(child: CircularProgressIndicator());
    }

    if(state.activeDonations.isEmpty){
      return Center(
        child: Text(userRole == roleInNeed ? 'You do not have any sent requests' : 'You do not have any waiting requests'),
      );
    }

    return ListView.builder(
      itemCount: state.activeDonations.length,
      itemBuilder: (context, index){
        final donation = state.activeDonations[index];
        final isDonor = (userRole == rolePersonal || userRole == roleCompany);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
          title: Text('Product id: ${donation.itemId}'),
          subtitle: Text('Status: ${donation.status.toUpperCase()}'),
          trailing: _buildActions(donation, isDonor, ref, context),
          onTap: donation.status == 'accepted' ? (){
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(donationId: donation.donationId, partnerName: 'User')));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are redirected to chat screen')),
            );
          }
          :null,
          ),
        );
      },
    );
  }
  Widget _buildActions(Donation donation, bool isDonor, WidgetRef ref, BuildContext context){
    final notifier = ref.read(donationsProvider.notifier);

    if(isDonor && donation.status == 'pending'){
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color:Colors.green),
            onPressed: () => notifier.respondToRequest(donation.donationId, 'rejected'),
          ),
        ],
      );
    }
    if(!isDonor && donation.status == 'accepted'){
      return ElevatedButton(
        onPressed: () => notifier.confirmPickup(donation.donationId),
        child: const Text('Recieved'),
      );
    }
    return const SizedBox.shrink();
  }
}