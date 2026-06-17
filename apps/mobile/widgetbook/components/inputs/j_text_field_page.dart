import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:jobbees_mobile/ui/ui.dart';

WidgetbookComponent jTextFieldPage() {
  return WidgetbookComponent(
    name: 'JTextField',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Email',
            controller: TextEditingController(),
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With prefix icon',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Email',
            controller: TextEditingController(),
            hintText: 'you@example.com',
            prefixIcon: Icons.mail_outline,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With value',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Email',
            controller: TextEditingController(
              text: 'aria.tasker123@example.com',
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With helper text',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Phone',
            controller: TextEditingController(),
            hintText: '+61 4XX XXX XXX',
            helperText: "We'll send a verification code by SMS",
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With error (Voice: state-the-problem)',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Email',
            controller: TextEditingController(text: 'aria@'),
            errorText: 'That email address is incomplete',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Disabled',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Email',
            controller: TextEditingController(
              text: 'aria.tasker123@example.com',
            ),
            enabled: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Password (obscured)',
        builder: (ctx) => _frame(
          JTextField(
            label: 'Password',
            controller: TextEditingController(text: 'hunter2'),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Compose — sign-up form snippet',
        builder: (ctx) => _frame(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JTextField(
                label: 'First name',
                controller: TextEditingController(text: 'Aria'),
              ),
              const SizedBox(height: JSpacing.base),
              JTextField(
                label: 'Email',
                controller: TextEditingController(),
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
              ),
              const SizedBox(height: JSpacing.base),
              JTextField(
                label: 'Mobile',
                controller: TextEditingController(),
                hintText: '+61 4XX XXX XXX',
                keyboardType: TextInputType.phone,
                helperText: "We'll verify with a 6-digit code",
              ),
              const SizedBox(height: JSpacing.lg),
              JButton.primary(
                label: 'Sign up',
                onPressed: () {},
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _frame(Widget child) => Padding(
  padding: const EdgeInsets.all(JSpacing.base),
  child: SingleChildScrollView(child: child),
);
