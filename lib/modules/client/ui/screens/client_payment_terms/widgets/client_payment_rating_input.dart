import 'package:flutter/material.dart';

class ClientPaymentRatingInput extends StatefulWidget {
  final Function(int rating, String comment) onSubmitted;

  const ClientPaymentRatingInput({super.key, required this.onSubmitted});

  @override
  State<ClientPaymentRatingInput> createState() => _ClientPaymentRatingInputState();
}

class _ClientPaymentRatingInputState extends State<ClientPaymentRatingInput> {
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starVal = index + 1;
            return IconButton(
              onPressed: _submitting
                  ? null
                  : () {
                      setState(() {
                        _selectedRating = starVal;
                      });
                    },
              icon: Icon(
                starVal <= _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
                size: 36,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          enabled: !_submitting,
          decoration: InputDecoration(
            hintText: 'Tulis pesan ulasan Anda di sini...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _submitting
                ? null
                : () async {
                    setState(() {
                      _submitting = true;
                    });
                    await widget.onSubmitted(
                      _selectedRating,
                      _commentCtrl.text,
                    );
                    if (mounted) {
                      setState(() {
                        _submitting = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Ulasan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
