#ifndef FRAMEARRANGEMENTYZFRAMECONTROLLER_H
#define FRAMEARRANGEMENTYZFRAMECONTROLLER_H

#include <QQuickPaintedItem>
#include <QPainter>
#include <QJsonArray>
#include <QJsonObject>
#include <QVariant>

class FrameArrangementYZController;

class FrameArrangementYZFrameController : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(int gridSpacing READ gridSpacing WRITE setGridSpacing NOTIFY gridSpacingChanged)
    Q_PROPERTY(int currentFrameNo READ currentFrameNo WRITE setCurrentFrameNo NOTIFY currentFrameNoChanged)
    Q_PROPERTY(QObject* frameController READ frameController WRITE setFrameController NOTIFY frameControllerChanged)
    Q_PROPERTY(QColor greenLineColor READ greenLineColor WRITE setGreenLineColor NOTIFY greenLineColorChanged)
    // View transform properties for zoom & pan
    Q_PROPERTY(double scaleFactor READ scaleFactor WRITE setScaleFactor NOTIFY scaleFactorChanged)
    Q_PROPERTY(double panX READ panX WRITE setPanX NOTIFY panXChanged)
    Q_PROPERTY(double panY READ panY WRITE setPanY NOTIFY panYChanged)

public:
    explicit FrameArrangementYZFrameController(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    // Property getters
    int gridSpacing() const { return m_gridSpacing; }
    int currentFrameNo() const { return m_currentFrameNo; }
    QObject* frameController() const { return m_controller; }
    QColor greenLineColor() const { return m_greenLineColor; }
    double scaleFactor() const { return m_scaleFactor; }
    double panX() const { return m_panX; }
    double panY() const { return m_panY; }

    // Property setters
    void setGridSpacing(int spacing);
    void setCurrentFrameNo(int frameNo);
    void setFrameController(QObject* controller);
    void setGreenLineColor(const QColor& color);
    void setScaleFactor(double s);
    void setPanX(double x);
    void setPanY(double y);

public slots:
    void regenerateDrawingData();

public:
    // Hit-test at item coordinates (pixels). Returns a map with keys:
    // success(bool), text(QString), index(int), axis(QString: "Y"|"Z"), orientation(QString), valueMM(double)
    Q_INVOKABLE QVariantMap hitTestAt(qreal x, qreal y, qreal pixelTolerance = 6.0) const;

signals:
    void gridSpacingChanged();
    void currentFrameNoChanged();
    void frameControllerChanged();
    void greenLineColorChanged();
    void scaleFactorChanged();
    void panXChanged();
    void panYChanged();

private:
    struct LineRecord {
        QLineF line;             // in world/item coords prior to painter scaling transform
        bool horizontal;         // true: horizontal (Y line per spec), false: vertical (Z line per spec)
        int index;               // L{index}, zero-based
        double valueMM;          // value in mm for the axis label
        QString axis;            // "Y" for horizontal, "Z" for vertical (per requested labeling)
    };

    // Drawing functions
    void drawFrameLines(QPainter *p, int centerX, int centerY, int spacing);
    void drawShipOutline(QPainter *p, int centerX, int centerY, int spacing);
    
    // Drawing helper functions for Y and Z coordinates (based on reference JavaScript)
    void drawZCoordinateLines(QPainter *p, int centerX, int centerY, int spacing, 
                            double zCoor, double spacingInLoop, const QString &thisSym, int index);
    void drawYCoordinateLines(QPainter *p, int centerX, int centerY, int spacing,
                            double yCoor, double spacingInLoop, const QString &thisSym, int index);

    // Validation and calculation helpers
    bool isValidFieldData(const QJsonObject& fieldData) const;
    int calculateLineCount(const QJsonObject& fieldData) const;
    double calculateLineSpacing(const QJsonObject& fieldData) const;
    QList<double> calculateLinePositions(double startValue, int lineCount, double spacing) const;
    bool hasYValue(const QJsonObject& fieldData) const;
    bool hasZValue(const QJsonObject& fieldData) const;

    // Data management
    void loadFrameData();
    QList<QJsonObject> getFrameDataForCurrentFrame() const;

    // Geometry helpers
    double distancePointToSegment(const QPointF &pt, const QLineF &seg) const;
    QPointF toWorldFromScreen(const QPointF &screenPt, int centerX, int centerY) const;

    // Member variables
    int m_gridSpacing;
    int m_currentFrameNo;
    QObject* m_controller;
    QColor m_greenLineColor;
    QJsonArray m_frameYZDrawing;
    // View transform state
    double m_scaleFactor;
    double m_panX;
    double m_panY;

    // Drawn lines metadata for hit testing (data lines only; exclude centerlines/outline)
    QVector<LineRecord> m_drawnLines;
};

#endif // FRAMEARRANGEMENTYZFRAMECONTROLLER_H
