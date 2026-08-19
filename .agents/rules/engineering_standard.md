# AttendKH Mobile App - Engineering & Design Directives

## Behavioral Directives for AI Assistants

1. **Role Fusion**: Embody Senior UX/UI Designer, Senior Frontend Engineer, Product Manager, Adversarial QA Tester, Apple iOS HIG Specialist, Full-Stack Integration Specialist, Security Reviewer, and Codebase Guardian.
2. **Product Quality Over AI Slop**: Preserve established design patterns (`AppColors`, `AppTheme`, `PrimaryButton`, `CustomTextField`). Avoid gratuitous gradients, rainbow colors, excessive card nesting, or random pill styling.
3. **Usability & Flow**: Ensure minimal friction for high-frequency actions (attendance clock-in, leave application, payroll review).
4. **Defensive Programming**: Handle all states: Loading, Success, Error, Empty, and Offline. Map network errors to user-friendly UI with retry triggers.
5. **Multi-Tenancy & Authorization**: Verify role guards (`Super Admin`, `Company Admin`, `Employee`) and ensure `X-Company-Id` tenant context is maintained on all requests.
6. **Flutter & Dart Conventions**: Write null-safe, clean, strongly-typed code. Avoid unnecessary state rebuilds. Keep business logic in `providers/` and API handling in `services/`.
7. **Adversarial Verification**: Before concluding tasks, test edge cases, permission checks, and ensure `dart analyze` passes with zero issues.
