//
//  SceneDelegate.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let tabBarController = MainTabBarController()
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        self.window = window
        PlayerManager.shared.setup(in: window)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarMinimizeBehavior = .onScrollDown

        self.tabs = [
            UITab(title: "Favoritos",
                  image: UIImage(systemName: "heart"),
                  identifier: "workouts") { _ in
                UINavigationController(rootViewController: FavoritesPodcastController())
            },
            UITab(title: "Descargas",
                  image: UIImage(systemName: "square.and.arrow.down.fill"),
                  identifier: "exercises") { _ in
                UINavigationController(rootViewController: PodcastSearchContainerController())
            },
            UISearchTab { _ in
                UINavigationController(rootViewController: SearchViewController())
            }
        ]
    }
}

import UIKit

class ExercisesViewController: UIViewController {

    // MARK: - Data

    private struct Exercise: Hashable {
        let id = UUID()
        let name: String
        let muscleGroup: String
    }

    private let filters = ["All", "Chest", "Back", "Legs", "Arms", "Core", "Shoulders"]
    private var selectedFilter = "All"

    private let exercises: [Exercise] = [
        .init(name: "Bench Press", muscleGroup: "Chest"),
        .init(name: "Pull Up", muscleGroup: "Back"),
        .init(name: "Squat", muscleGroup: "Legs"),
        .init(name: "Deadlift", muscleGroup: "Back"),
        .init(name: "Bicep Curl", muscleGroup: "Arms"),
        .init(name: "Plank", muscleGroup: "Core"),
        .init(name: "Overhead Press", muscleGroup: "Shoulders"),
        .init(name: "Lunges", muscleGroup: "Legs"),
        .init(name: "Push Up", muscleGroup: "Chest"),
        .init(name: "Row", muscleGroup: "Back"),
        .init(name: "Lateral Raise", muscleGroup: "Shoulders"),
        .init(name: "Tricep Dip", muscleGroup: "Arms"),
    ]

    // MARK: - Sections

    private enum Section: Int, CaseIterable {
        case filters
        case exercises
    }

    private enum Item: Hashable {
        case filter(String)
        case exercise(Exercise)
    }

    // MARK: - UI

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var glassContainer: UIVisualEffectView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Exercises"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        setupCollectionView()
        setupDataSource()
        setupFloatingButton()
        applySnapshot()
        
        view.backgroundColor = .blue

    }

    // MARK: - Collection View

    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, env in
            guard let self, let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {
            case .filters:
                // Sección horizontal de chips de filtros
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(80),
                    heightDimension: .absolute(36)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .estimated(80),
                    heightDimension: .absolute(36)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )

                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 8
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
                return section

            case .exercises:
                // Lista estilo "insetGrouped"
                var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                config.backgroundColor = .clear
                return NSCollectionLayoutSection.list(using: config, layoutEnvironment: env)
            }
        }

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self

        // CLAVE: dejar que el contenido pase debajo del tab bar
        // Esto es lo que activa el efecto blur de Liquid Glass.
        // Por defecto contentInsetAdjustmentBehavior es .automatic, que ya
        // ajusta los insets para que el último item sea alcanzable. No lo cambies.

        view.addSubview(collectionView)
    }

    private func setupDataSource() {
        // Cell para los chips de filtro
        let filterCellRegistration = UICollectionView.CellRegistration<FilterChipCell, String> {
            [weak self] cell, _, filter in
            cell.configure(title: filter, isSelected: filter == self?.selectedFilter)
        }

        // Cell para los ejercicios
        let exerciseCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Exercise> {
            cell, _, exercise in
            var content = cell.defaultContentConfiguration()
            content.text = exercise.name
            content.secondaryText = exercise.muscleGroup
            content.image = UIImage(systemName: "figure.strengthtraining.traditional")
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .filter(let name):
                return collectionView.dequeueConfiguredReusableCell(
                    using: filterCellRegistration, for: indexPath, item: name
                )
            case .exercise(let exercise):
                return collectionView.dequeueConfiguredReusableCell(
                    using: exerciseCellRegistration, for: indexPath, item: exercise
                )
            }
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.filters, .exercises])
        snapshot.appendItems(filters.map { .filter($0) }, toSection: .filters)

        let filtered = selectedFilter == "All"
            ? exercises
            : exercises.filter { $0.muscleGroup == selectedFilter }
        snapshot.appendItems(filtered.map { .exercise($0) }, toSection: .exercises)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Floating Button con Liquid Glass

    private func setupFloatingButton() {
        // 1) Configurar el botón
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "plus")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 20, weight: .bold
        )
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 14, leading: 14, bottom: 14, trailing: 14
        )

        let addButton = UIButton(configuration: config)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addAction(UIAction { [weak self] _ in
            self?.addExerciseTapped()
        }, for: .touchUpInside)

        // 2) Crear el contenedor con UIGlassEffect (iOS 26)
        let glassEffect = UIGlassEffect()
        glassEffect.isInteractive = true   // equivalente a .interactive() en SwiftUI

        glassContainer = UIVisualEffectView(effect: glassEffect)
        glassContainer.translatesAutoresizingMaskIntoConstraints = false
        glassContainer.layer.cornerRadius = 28
        glassContainer.clipsToBounds = true

        // 3) Meter el botón dentro del glass
        glassContainer.contentView.addSubview(addButton)
        view.addSubview(glassContainer)

        NSLayoutConstraint.activate([
            glassContainer.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16
            ),
            glassContainer.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16
            ),

            addButton.topAnchor.constraint(equalTo: glassContainer.contentView.topAnchor),
            addButton.bottomAnchor.constraint(equalTo: glassContainer.contentView.bottomAnchor),
            addButton.leadingAnchor.constraint(equalTo: glassContainer.contentView.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: glassContainer.contentView.trailingAnchor),
        ])
    }

    private func addExerciseTapped() {
        let alert = UIAlertController(
            title: "Add Exercise",
            message: "Aquí presentarías tu pantalla para añadir un ejercicio.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegate

extension ExercisesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .filters:
            selectedFilter = filters[indexPath.item]
            applySnapshot()
        case .exercises:
            collectionView.deselectItem(at: indexPath, animated: true)
            // Empuja al detalle aquí
        }
    }
}

import UIKit

class FilterChipCell: UICollectionViewCell {

    private let label = UILabel()
    private var glassView: UIVisualEffectView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // Glass background para el chip
        let glassEffect = UIGlassEffect()
        glassView = UIVisualEffectView(effect: glassEffect)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        glassView.layer.cornerRadius = 18
        glassView.clipsToBounds = true
        contentView.addSubview(glassView)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        glassView.contentView.addSubview(label)

        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: contentView.topAnchor),
            glassView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            glassView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            label.topAnchor.constraint(equalTo: glassView.contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: glassView.contentView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: glassView.contentView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: glassView.contentView.trailingAnchor, constant: -14),
        ])
    }

    func configure(title: String, isSelected: Bool) {
        label.text = title
        label.textColor = isSelected ? .white : .label

        // Tinte cuando está seleccionado
        if isSelected {
            contentView.backgroundColor = .systemPurple
            glassView.alpha = 0.3
        } else {
            contentView.backgroundColor = .clear
            glassView.alpha = 1.0
        }
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
    }
}

import UIKit

class WorkoutsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Workouts"
        view.backgroundColor = .green
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

class SearchViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        view.backgroundColor = .yellow

        let searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}
