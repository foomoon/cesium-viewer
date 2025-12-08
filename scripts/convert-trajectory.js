import { promises as fs } from 'node:fs'
import path from 'node:path'
import * as Cesium from 'cesium'

const [,, inputPath, outputPath] = process.argv

if (!inputPath || !outputPath) {
  console.error('Usage: node scripts/convert-trajectory.js <input.txt> <output.json>')
  process.exit(1)
}

const toTrajectoryId = (p) => path.basename(p, path.extname(p))
const toTitle = (str) =>
  str
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, (m) => m.toUpperCase())

const parseLine = (line) => line.trim().split(/\s+/).map(Number)

const FEET_TO_METERS = 0.3048

const ecefToCartographic = (x, y, z) => {
  const cartesian = new Cesium.Cartesian3(
    x * FEET_TO_METERS,
    y * FEET_TO_METERS,
    z * FEET_TO_METERS,
  )
  const carto = Cesium.Cartographic.fromCartesian(cartesian)
  return {
    lat: +Cesium.Math.toDegrees(carto.latitude).toFixed(6),
    lon: +Cesium.Math.toDegrees(carto.longitude).toFixed(6),
    altitude: Math.round(carto.height),
  }
}

const loadFile = async (filePath) => {
  const raw = await fs.readFile(filePath, 'utf8')
  const lines = raw.split(/\r?\n/).filter((l) => l.trim().length > 0)
  const dataLines = lines.filter((l) => !l.trim().startsWith('Time'))

  const positions = dataLines.map((line) => {
    const cols = parseLine(line)
    const [ , x, y, z ] = cols
    return ecefToCartographic(x, y, z)
  })

  return positions
}

const main = async () => {
  const positions = await loadFile(inputPath)
  if (!positions.length) {
    console.error('No positions parsed from file.')
    process.exit(1)
  }

  const trajectory = {
    id: toTrajectoryId(inputPath),
    name: toTitle(toTrajectoryId(inputPath)),
    type: 'other',
    velocityProfile: 'other',
    maneuverability: 'no-waypoint',
    convergence: 'nominal',
    positions,
    waypoints: [],
  }

  await fs.writeFile(outputPath, JSON.stringify([trajectory], null, 2))
  console.log(`Wrote ${positions.length} positions to ${outputPath}`)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
