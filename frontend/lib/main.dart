import 'package:flutter/material.dart';
import 'controllers/session_controller.dart';
import 'screens/screens.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppRoot(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _sessionController = SessionController();

  @override
  void initState() {
    super.initState();
    _sessionController.addListener(_handleSessionNotice);
  }

  void _handleSessionNotice() {
    final notice = _sessionController.takeNotice();
    if (notice == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final message = switch (notice) {
        SessionNotice.requestSubmitted => "Request sent",
      };

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessionController,
      builder: (_, _) => _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    return switch (_sessionController.status) {
      SessionStatus.loading => const LoadingScreen(),

      SessionStatus.error => const ErrorScreen(),

      SessionStatus.menu => MenuScreen(menuItems: _sessionController.menuItems),

      SessionStatus.learn => LearnScreen(
        viewData: _sessionController.learnViewData,
        onBack: _sessionController.onMenu,
        turn: _sessionController.learnTurnCard,
        next: _sessionController.learnNext,
        playAudio: _sessionController.learnPlayAudio,
        setSelectedGroups: _sessionController.learnSetSelectedGroups,
      ),

      SessionStatus.quiz => QuizScreen(
        viewData: _sessionController.quizViewData,
        onBack: _sessionController.onMenu,
        submit: _sessionController.quizSubmit,
        playAudio: _sessionController.quizPlayAudio,
        setShowPronunciationButtons:
            _sessionController.quizSetShowPronunciationButtons,
      ),

      SessionStatus.memory => MemoryScreen(
        viewData: _sessionController.memoryViewData,
        onBack: _sessionController.onMenu,
        onSelect: _sessionController.memorySelect,
        onNewGame: _sessionController.memoryStartNewGame,
      ),

      SessionStatus.accents => AccentsScreen(
        viewData: _sessionController.accentedViewData,
        onBack: _sessionController.onMenu,
        onNext: _sessionController.accentsNext,
        onDrop: _sessionController.accentsOnDrop,
        playAudio: _sessionController.accentsPlayAudio,
      ),

      SessionStatus.request => RequestScreen(
        viewData: _sessionController.requestViewData,
        onBack: _sessionController.onMenu,
        onSourceChanged: _sessionController.requestUpdateSource,
        onSubmit: _sessionController.requestSubmit,
      ),

      SessionStatus.resolve => ResolveScreen(
        viewData: _sessionController.requestListViewData,
        onBack: _sessionController.onMenu,
        onRetry: _sessionController.resolutionRetry,
        onSelect: _sessionController.resolutionSelect,
      ),

      SessionStatus.resolveForm => ResolutionFormScreen(
        viewData: _sessionController.resolutionFormViewData,
        onBack: _sessionController.onResolutionList,
        onSourceChanged: _sessionController.resolutionUpdateSource,
        onTargetChanged: _sessionController.resolutionUpdateTarget,
        onSubmit: _sessionController.resolutionSubmit,
      ),
    };
  }

  @override
  void dispose() {
    _sessionController.removeListener(_handleSessionNotice);
    _sessionController.dispose();
    super.dispose();
  }
}
