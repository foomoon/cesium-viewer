<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from "vue";
import * as Cesium from "cesium";
import { get } from "@vueuse/core";

const props = defineProps({
  trajectories: {
    type: Array,
    default: () => [],
  },
  selectedTrajectoryId: {
    type: String,
    default: "",
  },
  useOfflineMap: {
    type: Boolean,
    default: false,
  },
  useFlatMap: {
    type: Boolean,
    default: false,
  },
  useLighting: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(["coordinate-selected"]);

const containerRef = ref(null);
const viewerRef = ref(null);
const handlerRef = ref(null);
const trajectoryEntities = new Map();
let selectedPointEntity = null;
const markerEntities = new Map();
const POINT_HEIGHT_OFFSET = 25;

const defaultBaseLayer = //Cesium.ImageryLayer.fromProviderAsync(
  Cesium.ArcGisMapServerImageryProvider.fromUrl(
    "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer",
    {}
  );

const NaturalEarthIILayer = //new Cesium.ImageryLayer(
  new Cesium.UrlTemplateImageryProvider({
    url: "/cesium/Assets/Textures/NaturalEarthII/{z}/{x}/{reverseY}.jpg",
    tilingScheme: new Cesium.GeographicTilingScheme(),
    maximumLevel: 2, // Natural Earth II has a limited zoom level
  });

  // Your local Blue Marble tiles (XYZ, Web Mercator)
  const blueMarbleProvider = new Cesium.UrlTemplateImageryProvider({
    url: "/cesium/tiles/blue-marble/{z}/{x}/{y}.jpg",
    tilingScheme: new Cesium.WebMercatorTilingScheme(),
    minimumLevel: 0,
    maximumLevel: 6, // must match how you generated tiles
    // Optional: if your server is slow, you can increase retries
    // retryAttempts: 3, // (Cesium doesn't expose on all versions)
  });


// const Sentinel2CloudlessLayer =
//   new Cesium.UrlTemplateImageryProvider({
//     url: 'https://tiles.maps.eox.at/wmts/1.0.0/s2cloudless-2020/default/g/{z}/{x}/{y}.jpg',
//     credit: '© Sentinel-2 Cloudless by EOX'
//   });



const getImageryLayer = (provider) => {
  return new Cesium.ImageryLayer.fromProviderAsync(provider);
};

const getImageryProvider = (isDefault) =>
  isDefault ? blueMarbleProvider : defaultBaseLayer;

const applyImageryProvider = (offline) => {
  if (!viewerRef.value) return;
  const layers = viewerRef.value.imageryLayers;
  const provider = getImageryProvider(offline);
  layers.removeAll();
  layers.add(getImageryLayer(provider), 0);
};

const applySceneMode = (useFlat) => {
  if (!viewerRef.value) return;
  const scene = viewerRef.value.scene;
  if (useFlat && scene.mode !== Cesium.SceneMode.SCENE2D) {
    scene.morphTo2D(0.8);
  } else if (!useFlat && scene.mode !== Cesium.SceneMode.SCENE3D) {
    scene.morphTo3D(0.8);
  }
};

const applyLighting = (enabled) => {
  if (!viewerRef.value) return;
  viewerRef.value.scene.globe.enableLighting = enabled;
};

const createViewer = () => {
  if (!containerRef.value) return;

  viewerRef.value = new Cesium.Viewer(containerRef.value, {
    animation: false,
    baseLayerPicker: false,
    fullscreenButton: false,
    geocoder: false,
    homeButton: false,
    infoBox: false,
    navigationHelpButton: false,
    sceneModePicker: false,
    selectionIndicator: false,
    timeline: false,
    vrButton: false,
    navigationInstructionsInitiallyVisible: false,
    baseLayer: getImageryLayer(getImageryProvider(props.useOfflineMap)),
  });

  // after 3 seconds, switch to default base layer
  // setTimeout(() => {
  //   applyImageryProvider(props.useOfflineMap)
  // }, 5000)

  viewerRef.value.scene.globe.enableLighting = props.useLighting;
  viewerRef.value.scene.globe.showGroundAtmosphere = true;
  viewerRef.value.scene.globe.depthTestAgainstTerrain = true;
  viewerRef.value.scene.globe.minimumZoomDistance = 500000;
  viewerRef.value.cesiumWidget.creditContainer.style.display = "none";

  applySceneMode(props.useFlatMap);
  applyLighting(props.useLighting);
  setClickHandler();
  resetView();
  syncTrajectories(props.trajectories);
  highlightSelected(props.selectedTrajectoryId);
};

const resetView = () => {
  if (!viewerRef.value) return;
  viewerRef.value.camera.flyTo({
    destination: Cesium.Cartesian3.fromDegrees(-98.5795, 39.8283, 2500000),
    duration: 1.4,
  });
};

const setClickHandler = () => {
  if (!viewerRef.value) return;
  handlerRef.value = new Cesium.ScreenSpaceEventHandler(
    viewerRef.value.scene.canvas
  );
  handlerRef.value.setInputAction((movement) => {
    const scene = viewerRef.value.scene;
    const cartesian =
      scene.pickPosition(movement.position) ||
      viewerRef.value.camera.pickEllipsoid(
        movement.position,
        scene.globe.ellipsoid
      );

    if (!cartesian) return;
    const cartographic = Cesium.Cartographic.fromCartesian(cartesian);
    addOrUpdateSelectedPoint(cartesian);
    emit("coordinate-selected", {
      lat: Cesium.Math.toDegrees(cartographic.latitude),
      lon: Cesium.Math.toDegrees(cartographic.longitude),
    });
  }, Cesium.ScreenSpaceEventType.LEFT_CLICK);
};

const addOrUpdateSelectedPoint = (cartesianPosition) => {
  if (!viewerRef.value) return;
  const raised = raiseCartesian(cartesianPosition, POINT_HEIGHT_OFFSET);
  if (selectedPointEntity) {
    selectedPointEntity.position = raised;
    return;
  }
  selectedPointEntity = viewerRef.value.entities.add({
    position: raised,
    point: {
      pixelSize: 10,
      color: Cesium.Color.fromCssColorString("#2563eb").withAlpha(0.95),
      outlineColor: Cesium.Color.WHITE.withAlpha(0.9),
      outlineWidth: 2,
    },
  });
};

const getStyleFor = (id) => {
  const isActive = id === props.selectedTrajectoryId;
  return {
    color: isActive ? "#2563eb" : "#94a3b8",
    width: isActive ? 4 : 2.5,
    alpha: isActive ? 1 : 0.5,
  };
};

const groundTrackPositions = (trajectory) => {
  if (!trajectory) return [];
  const points = [];
  const source = trajectory.positions || [];
  if (source.length) {
    points.push({ ...source[0], altitude: 0, height: 0 });
  }
  (trajectory.waypoints || []).forEach((wp) => {
    points.push({ ...wp, altitude: 0, height: 0 });
  });
  if (source.length > 1) {
    points.push({ ...source[source.length - 1], altitude: 0, height: 0 });
  }
  // Ensure we have at least two points; otherwise fall back to original
  if (points.length < 2) {
    return source.map((p) => ({ ...p, altitude: 0, height: 0 }));
  }
  // Remove consecutive duplicates that might appear if waypoints match endpoints
  return points.filter((p, idx) => {
    if (idx === 0) return true;
    const prev = points[idx - 1];
    return !(p.lat === prev.lat && p.lon === prev.lon);
  });
};

const buildPolylinePositions = (trajectory) => {
  if (!trajectory || !trajectory.positions?.length) return [];
  const useGroundTrack = trajectory.id !== props.selectedTrajectoryId;
  const source = useGroundTrack
    ? groundTrackPositions(trajectory)
    : trajectory.positions;
  if (!source.length) return [];

  if (useGroundTrack) {
    return Cesium.Cartesian3.fromDegreesArray(
      source.flatMap((p) => [p.lon, p.lat])
    );
  }

  return Cesium.Cartesian3.fromDegreesArrayHeights(
    source.flatMap((p) => [p.lon, p.lat, p.altitude ?? 0])
  );
};

const syncTrajectories = (list) => {
  if (!viewerRef.value) return;
  const ids = new Set(list.map((item) => item.id));

  for (const [id, entity] of trajectoryEntities.entries()) {
    if (!ids.has(id)) {
      viewerRef.value.entities.remove(entity);
      trajectoryEntities.delete(id);
    }
  }

  list.forEach((item) => {
    const positions = buildPolylinePositions(item);
    const { color, width, alpha } = getStyleFor(item.id);
    const material = new Cesium.ColorMaterialProperty(
      Cesium.Color.fromCssColorString(color).withAlpha(alpha)
    );

    if (trajectoryEntities.has(item.id)) {
      const entity = trajectoryEntities.get(item.id);
      entity.polyline.positions = positions;
      entity.polyline.material = material;
      entity.polyline.width = width;
    } else {
      const entity = viewerRef.value.entities.add({
        id: item.id,
        polyline: {
          positions,
          material,
          width,
          clampToGround: false,
          arcType: Cesium.ArcType.GEODESIC,
        },
      });
      trajectoryEntities.set(item.id, entity);
    }
  });

  setMarkersForSelected();
};

const highlightSelected = async (selectedId) => {
  if (!viewerRef.value) return;
  // Re-sync to swap ballistic tracks between ground-track and full profile
  syncTrajectories(props.trajectories);

  if (selectedId && trajectoryEntities.has(selectedId)) {
    const entity = trajectoryEntities.get(selectedId);
    await viewerRef.value.flyTo(entity, {
      duration: 1.2,
    });
  }
};

onMounted(() => {
  createViewer();
});

onBeforeUnmount(() => {
  handlerRef.value?.destroy?.();
  if (viewerRef.value && !viewerRef.value.isDestroyed()) {
    clearMarkers();
    if (selectedPointEntity) {
      viewerRef.value.entities.remove(selectedPointEntity);
    }
    viewerRef.value.entities.removeAll();
    viewerRef.value.destroy();
  }
});

watch(
  () => props.trajectories,
  (next) => syncTrajectories(next),
  { deep: true }
);

watch(
  () => props.selectedTrajectoryId,
  (next) => highlightSelected(next)
);

watch(
  () => props.useOfflineMap,
  (next) => applyImageryProvider(next)
);

watch(
  () => props.useFlatMap,
  (next) => applySceneMode(next)
);

watch(
  () => props.useLighting,
  (next) => applyLighting(next)
);

defineExpose({ resetView });

const raiseCartesian = (cartesian, offsetMeters) => {
  const carto = Cesium.Cartographic.fromCartesian(cartesian);
  carto.altitude = (carto.altitude || 0) + offsetMeters;
  return Cesium.Cartesian3.fromRadians(
    carto.longitude,
    carto.latitude,
    carto.altitude
  );
};

const clearMarkers = () => {
  if (!viewerRef.value) return;
  markerEntities.forEach((markers) => {
    markers.forEach((m) => viewerRef.value.entities.remove(m));
  });
  markerEntities.clear();
};

const setMarkersForSelected = () => {
  if (!viewerRef.value) return;
  clearMarkers();
  const selectedId = props.selectedTrajectoryId;
  const trajectory = props.trajectories.find((t) => t.id === selectedId);
  if (!trajectory) return;

  const markers = [];
  trajectory.positions.forEach((p) => {
    if (!p.marker) return;
    const markerStyle = getMarkerStyle(p.marker);
    const cartesian = Cesium.Cartesian3.fromDegrees(
      p.lon,
      p.lat,
      (p.altitude ?? 0) + markerStyle.heightOffset
    );
    const marker = viewerRef.value.entities.add({
      position: cartesian,
      point: {
        pixelSize: markerStyle.pixelSize,
        color: markerStyle.color,
        outlineColor: markerStyle.outlineColor,
        outlineWidth: markerStyle.outlineWidth,
      },
      label: markerStyle.label
        ? {
            text: markerStyle.label,
            font: '12px "Helvetica Neue", Arial, sans-serif',
            fillColor: Cesium.Color.WHITE,
            outlineColor: Cesium.Color.fromCssColorString("#0f172a"),
            outlineWidth: 3,
            pixelOffset: new Cesium.Cartesian2(0, -18),
            style: Cesium.LabelStyle.FILL_AND_OUTLINE,
          }
        : undefined,
    });
    markers.push(marker);
  });

  if (markers.length) {
    markerEntities.set(selectedId, markers);
  }
};

const getMarkerStyle = (markerType) => {
  switch (markerType) {
    case "start":
      return {
        color: Cesium.Color.fromCssColorString("#22c55e").withAlpha(0.95),
        outlineColor: Cesium.Color.WHITE.withAlpha(0.9),
        outlineWidth: 2,
        pixelSize: 10,
        heightOffset: 50,
        label: "Launch",
      };
    case "end":
      return {
        color: Cesium.Color.fromCssColorString("#ef4444").withAlpha(0.95),
        outlineColor: Cesium.Color.WHITE.withAlpha(0.9),
        outlineWidth: 2,
        pixelSize: 10,
        heightOffset: 50,
        label: "Aim",
      };
    case "waypoint":
    default:
      return {
        color: Cesium.Color.fromCssColorString("#475569").withAlpha(0.85),
        outlineColor: Cesium.Color.WHITE.withAlpha(0.85),
        outlineWidth: 1.5,
        pixelSize: 8,
        heightOffset: 25,
        label: undefined,
      };
  }
};
</script>

<template>
  <div class="relative h-full w-full overflow-hidden rounded-2xl border">
    <div ref="containerRef" class="h-full w-full bg-slate-900/40" />
  </div>
</template>
