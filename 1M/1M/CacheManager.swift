

import CoreData

struct CacheManager {
static func isCached(_ fetchedAt: Date, ttlHours: Int) -> Bool {
let expiry = fetchedAt.addingTimeInterval(TimeInterval(ttlHours *
3600))
return Date() <= expiry
    }
}
