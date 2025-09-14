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

public:
    explicit FrameArrangementYZFrameController(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    // Property getters
    int gridSpacing() const { return m_gridSpacing; }
    int currentFrameNo() const { return m_currentFrameNo; }
    QObject* frameController() const { return m_controller; }
    QColor greenLineColor() const { return m_greenLineColor; }

    // Property setters
    void setGridSpacing(int spacing);
    void setCurrentFrameNo(int frameNo);
    void setFrameController(QObject* controller);
    void setGreenLineColor(const QColor& color);

public slots:
    void regenerateDrawingData();

signals:
    void gridSpacingChanged();
    void currentFrameNoChanged();
    void frameControllerChanged();
    void greenLineColorChanged();

private:
    // Drawing functions
    void drawFrameLines(QPainter *p, int centerX, int centerY, int spacing);
    void drawShipOutline(QPainter *p, int centerX, int centerY, int spacing);
    
    // Drawing helper functions for Y and Z coordinates (based on reference JavaScript)
    void drawZCoordinateLines(QPainter *p, int centerX, int centerY, int spacing, 
                            double zCoor, double spacingInLoop, const QString &thisSym);
    void drawYCoordinateLines(QPainter *p, int centerX, int centerY, int spacing,
                            double yCoor, double spacingInLoop, const QString &thisSym);

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

    // Member variables
    int m_gridSpacing;
    int m_currentFrameNo;
    QObject* m_controller;
    QColor m_greenLineColor;
    QJsonArray m_frameYZDrawing;
};

#endif // FRAMEARRANGEMENTYZFRAMECONTROLLER_H
