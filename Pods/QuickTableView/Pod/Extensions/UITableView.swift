//
//  Copyright 2016 Lionheart Software LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

public extension UITableView {
    // MARK: !!!
    func registerClasses<T>(_ cellClasses: [T.Type]) where T: QuickTableViewCellIdentifiableFixedHeight {
        for cellClass in cellClasses {
            registerClass(cellClass)
        }
    }

    // MARK: !!!
    func registerClasses<T>(_ cellClasses: [T.Type], withEstimatedRowHeight estimatedRowHeight: CGFloat = 44) where T: QuickTableViewCellIdentifiableAutomaticHeight {
        for cellClass in cellClasses {
            registerClass(cellClass)
        }

        self.estimatedRowHeight = estimatedRowHeight
        rowHeight = UITableViewAutomaticDimension
    }

    func registerClass(_ cellClass: QuickTableViewCellIdentifiable.Type) {
        let identifier = cellClass.identifier
        guard let cellClass = cellClass as? AnyClass else {
            return
        }

        register(cellClass, forCellReuseIdentifier: identifier)
    }

    func dequeueReusableCell<T>(forIndexPath indexPath: IndexPath) -> T where T: QuickTableViewCellIdentifiable {
        return dequeueReusableCell(withIdentifier: T.identifier, for: indexPath) as! T
    }
}
