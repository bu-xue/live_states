import 'dart:async';
import 'dart:math';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:live_states/live_states.dart';
import 'package:live_states_devtools/src/models.dart';

import '../states_provider.dart';

part 'data_graph_view.vm.dart';

// Visual constants for rendering the graph
const _cLiveData = Color(0xFF00E5FF); // Cyan for LiveData
const _cComputed = Color(0xFFFFD600); // Amber for Computed states
const _cScope = Color(0xFFE040FB);    // Purple for Scopes
const _cEdge = Color(0x1AFFFFFF);    // Base color for connection lines
const _cFlow = Color(0xFFFFFFFF);     // Color for animated flow particles
const _cNodeBg = Color(0xFF1E1E24);   // Dark background for nodes
const _nodeW = 168.0;                 // Width of a data node
const _nodeH = 86.0;                  // Height of a data node

/// A widget that visualizes the data flow topology of live_states.
class DataGraphView extends LiveWidget {
  const DataGraphView({super.key});

  @override
  DataGraphViewVM createViewModel() => DataGraphViewVM();

  @override
  Widget build(BuildContext context, DataGraphViewVM viewModel) {
    return Column(
      children: [
        const AreaPaneHeader(
          title: Text('Live Data Flow Topology'),
          actions: [
            Text(
              'Double-click node to select',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: FreeLiveScope(builder: (context, _) {
            if (!viewModel.hasNodes.value) {
              return const Center(
                child: Text('No data flow detected', style: TextStyle(color: Colors.grey)),
              );
            }

            return LayoutBuilder(builder: (context, constraints) {
              // Offset the graph to the left center by default for horizontal layout
              final center = Offset(120.0, constraints.maxHeight / 2);
              
              return InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.1,
                maxScale: 3.5,
                child: Container(
                  width: 3000,
                  height: 2500,
                  color: const Color(0xFF0B0B0E),
                  child: FreeLiveScope(builder: (context, _) {
                    final posMap = viewModel.positions.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Layer 1: Static grid background
                        const RepaintBoundary(child: _StaticBackground()),
                        
                        // Layer 2: Connection edges with flow animations
                        ...viewModel.graph!.edges.map((edge) {
                          return FreeLiveScope(builder: (context, _) {
                            final src = center + (posMap[edge.subject] ?? Offset.zero);
                            final dst = center + (posMap[edge.observer] ?? Offset.zero);
                            return _EdgeWidget(
                              edge: edge,
                              src: src,
                              dst: dst,
                              animValue: viewModel.edgesCtrl[edge]?.value,
                            );
                          });
                        }),
                        
                        // Layer 3: Interactive data nodes
                        ...?viewModel.graph?.nodes.map((node) {
                          return FreeLiveScope(builder: (context, _) {
                            final pos = center + (posMap[node] ?? Offset.zero);
                            return _NodeWidget(
                              node: node,
                              pos: pos,
                              animValue: viewModel.nodesCtrl[node]?.value,
                              onDoubleTap: () => viewModel.selectNode(node),
                            );
                          });
                        }),
                      ],
                    );
                  }),
                ),
              );
            });
          }),
        ),
      ],
    );
  }
}

class _StaticBackground extends StatelessWidget {
  const _StaticBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _BackgroundPainter(),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const spacing = 50.0;
    
    // Draw vertical grid lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    // Draw horizontal grid lines
    for (double j = 0; j < size.height; j += spacing) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
    
    // Radial vignette effect for depth
    final radialGradient = RadialGradient(
      colors: [Colors.white.withValues(alpha: 0.03), Colors.transparent],
      center: Alignment.center,
      radius: 1.2,
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = radialGradient);
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => false;
}

class _NodeWidget extends StatelessWidget {
  final Node node;
  final Offset pos;
  final double? animValue;
  final VoidCallback? onDoubleTap;

  const _NodeWidget({
    required this.node,
    required this.pos,
    this.animValue,
    this.onDoubleTap,
  });

  /// Builds a detailed tooltip string for the node.
  String _buildTooltip() {
    final buffer = StringBuffer();
    buffer.writeln('ID: ${node.id}');
    if (node.debugName != null) buffer.writeln('Name: ${node.debugName}');
    buffer.writeln('Type: ${node.type.name.toUpperCase()}');
    if (node.currentValue != null) buffer.writeln('Value: ${node.currentValue}');
    
    if (node.subscriptions.isNotEmpty) {
      buffer.writeln('Subjects: ${node.subscriptions.map((s) => s.debugName ?? s.id).join(', ')}');
    }
    if (node.observers.isNotEmpty) {
      buffer.writeln('Observers: ${node.observers.map((o) => o.debugName ?? o.id).join(', ')}');
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: pos.dx - _nodeW / 2,
      top: pos.dy - _nodeH / 2,
      child: Tooltip(
        message: _buildTooltip(),
        waitDuration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 11),
        child: GestureDetector(
          onDoubleTap: onDoubleTap,
          behavior: HitTestBehavior.opaque,
          child: RepaintBoundary(
            child: _buildBody(animValue ?? 0.0),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double animValue) {
    return CustomPaint(
      size: const Size(_nodeW, _nodeH),
      painter: _NodePainter(
        type: node.type,
        debugName: node.debugName ?? node.id,
        currentValue: node.currentValue,
        animValue: animValue,
      ),
    );
  }
}

class _EdgeWidget extends StatelessWidget {
  final Edge edge;
  final Offset src;
  final Offset dst;
  final double? animValue;

  const _EdgeWidget({
    required this.edge,
    required this.src,
    required this.dst,
    this.animValue,
  });

  @override
  Widget build(BuildContext context) {
    final rect = Rect.fromPoints(src, dst).inflate(120);
    return Positioned.fromRect(
      rect: rect,
      child: RepaintBoundary(
        child: _buildPaint(rect, animValue ?? 0.0),
      ),
    );
  }

  Widget _buildPaint(Rect area, double animValue) {
    return CustomPaint(
      painter: _EdgePainter(
        src: src - area.topLeft,
        dst: dst - area.topLeft,
        animValue: animValue,
      ),
    );
  }
}

class _NodePainter extends CustomPainter {
  final NodeType type;
  final String debugName;
  final String? currentValue;
  final double animValue;

  _NodePainter({
    required this.type,
    required this.debugName,
    this.currentValue,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final pulse = sin(animValue * pi).clamp(0.0, 1.0);
    final color = _getNodeColor(type);
    final path = _getNodePath(rect, type);

    // 1. Shadow and dynamic glow effect
    canvas.drawPath(
      path.shift(const Offset(0, 4)), 
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
    );

    if (pulse > 0.01) {
      canvas.drawPath(
        path, 
        Paint()
          ..color = color.withValues(alpha: 0.4 * pulse)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * pulse)
      );
    }

    // 2. Main node body (Glassmorphism effect)
    canvas.drawPath(
      path, 
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: [_cNodeBg, _cNodeBg.withValues(alpha: 0.85)]
        ).createShader(rect)
    );

    // 3. Highlighted border
    canvas.drawPath(
      path, 
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: [color, color.withValues(alpha: 0.1)], 
          stops: const [0.2, 1.0]
        ).createShader(rect)
    );

    _paintContent(canvas, center, size, color);
  }

  void _paintContent(Canvas canvas, Offset center, Size size, Color color) {
    // 1. Type label capsule (centered at the top)
    final typeTp = TextPainter(
        text: TextSpan(
            text: type.name.toUpperCase(),
            style: TextStyle(
              color: color.withValues(alpha: 0.95), 
              fontSize: 8, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.8
            )),
        textDirection: TextDirection.ltr)..layout();
    
    // Decorative lines flanking the type label
    final linePaint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 1;
    canvas.drawLine(Offset(20, 16), Offset(size.width/2 - typeTp.width/2 - 8, 16), linePaint);
    canvas.drawLine(Offset(size.width/2 + typeTp.width/2 + 8, 16), Offset(size.width - 20, 16), linePaint);

    typeTp.paint(canvas, Offset(size.width / 2 - typeTp.width / 2, 12));

    // 2. Debug name (positioned below type label)
    final bool hasValue = currentValue != null && currentValue!.isNotEmpty;
    final nameTp = TextPainter(
        text: TextSpan(
            text: debugName,
            style: const TextStyle(
              color: Color(0xFFF0F0F0), 
              fontSize: 13, 
              fontWeight: FontWeight.w700, 
              letterSpacing: 0.4
            )),
        maxLines: 1, 
        ellipsis: '...', 
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: size.width - 24);
    
    final nameY = hasValue ? center.dy - 6 : center.dy + 2;
    nameTp.paint(canvas, Offset(size.width / 2 - nameTp.width / 2, nameY - nameTp.height / 2));

    // 3. Current value bubble (auto-truncated)
    if (hasValue) {
      final valTp = TextPainter(
          text: TextSpan(
              text: currentValue,
              style: TextStyle(
                color: color.withValues(alpha: 0.9), 
                fontSize: 10.5, 
                fontFamily: 'monospace', 
                fontWeight: FontWeight.w600
              )),
          maxLines: 1, 
          ellipsis: '...', 
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: size.width - 40);

      final valY = center.dy + 20;
      final valRect = Rect.fromCenter(
        center: Offset(size.width / 2, valY), 
        width: max(valTp.width + 16, 50), 
        height: 18
      );
      
      final rRect = RRect.fromRectAndRadius(valRect, const Radius.circular(4));
      canvas.drawRRect(rRect, Paint()..color = Colors.black.withValues(alpha: 0.3));
      canvas.drawRRect(rRect, Paint()..color = color.withValues(alpha: 0.08));
      canvas.drawRRect(rRect, Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5..color = color.withValues(alpha: 0.3));

      valTp.paint(canvas, Offset(size.width / 2 - valTp.width / 2, valY - valTp.height / 2));
    }
  }

  Path _getNodePath(Rect rect, NodeType type) {
    switch (type) {
      case NodeType.livedata:
        return Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));
      case NodeType.computed:
        final w = rect.width; 
        final h = rect.height; 
        final x = rect.left; 
        final y = rect.top; 
        const offset = 20.0;
        return Path()
          ..moveTo(x + offset, y)
          ..lineTo(x + w - offset, y)
          ..lineTo(x + w, y + h / 2)
          ..lineTo(x + w - offset, y + h)
          ..lineTo(x + offset, y + h)
          ..lineTo(x, y + h / 2)
          ..close();
      case NodeType.scope:
        return Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
    }
  }

  Color _getNodeColor(NodeType type) {
    switch (type) {
      case NodeType.livedata: return _cLiveData;
      case NodeType.computed: return _cComputed;
      case NodeType.scope: return _cScope;
    }
  }

  @override
  bool shouldRepaint(_NodePainter old) =>
      old.animValue != animValue || old.currentValue != currentValue;
}

class _EdgePainter extends CustomPainter {
  final Offset src;
  final Offset dst;
  final double animValue;

  _EdgePainter({required this.src, required this.dst, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getHorizontalCurvedPath(src, dst);
    
    // Shadow for connection lines
    canvas.drawPath(
      path, 
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
    );
    
    // Main connection line
    canvas.drawPath(
      path, 
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(colors: [_cEdge, _cEdge.withValues(alpha: 0.1)]).createShader(Rect.fromPoints(src, dst))
    );
    
    _paintArrow(canvas, path);
    
    // Particle flow effect
    if (animValue > 0.0 && animValue < 1.0) {
      _paintFlow(canvas, path);
    }
  }

  Path _getHorizontalCurvedPath(Offset src, Offset dst) {
    final path = Path()..moveTo(src.dx, src.dy);
    final dx = (dst.dx - src.dx).abs();
    final controlOffset = min(dx * 0.5, 100.0);
    path.cubicTo(src.dx + controlOffset, src.dy, dst.dx - controlOffset, dst.dy, dst.dx, dst.dy);
    return path;
  }

  void _paintArrow(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().first;
    const arrowOffset = 42.0;
    if (metrics.length < arrowOffset) return;
    final tangent = metrics.getTangentForOffset(metrics.length - arrowOffset)!;
    
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(tangent.angle);
    
    final arrowPaint = Paint()
      ..color = _cEdge.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
      
    canvas.drawPath(Path()..moveTo(-8, -5)..lineTo(0, 0)..lineTo(-8, 5), arrowPaint);
    canvas.restore();
  }

  void _paintFlow(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().first;
    final tangent = metrics.getTangentForOffset(metrics.length * animValue)!;
    final pos = tangent.position;
    
    canvas.drawCircle(pos, 2.5, Paint()..color = _cFlow);
    
    // Comet tail effect
    for (int i = 1; i < 8; i++) {
      final t = (animValue - i * 0.015).clamp(0.0, 1.0);
      final trailPos = metrics.getTangentForOffset(metrics.length * t)!.position;
      canvas.drawCircle(trailPos, 2.5 * (1 - i / 8), Paint()..color = _cFlow.withValues(alpha: 0.6 * (1 - i / 8)));
    }
    
    // Core glow
    canvas.drawCircle(
      pos, 
      10, 
      Paint()
        ..color = _cFlow.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.animValue != animValue || old.src != src || old.dst != dst;
}
