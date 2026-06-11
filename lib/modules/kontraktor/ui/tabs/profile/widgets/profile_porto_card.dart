import 'package:flutter/material.dart';
import 'package:buildmatch/data/models/portfolio_model.dart';

class ProfilePortoCard extends StatelessWidget {
  final PortfolioModel portfolio;

  const ProfilePortoCard({
    super.key,
    required this.portfolio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: portfolio.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(portfolio.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey.shade300,
      ),
    );
  }
}
