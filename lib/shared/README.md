# Shared - Componentes Compartidos UI

Esta carpeta contiene componentes de UI y recursos compartidos entre diferentes features.

## 📁 Componentes Shared

### 🎨 **Widgets**
Componentes de UI reutilizables
- Botones personalizados
- Cards y containers
- Loading indicators
- Componentes de audio (player, wave, etc.)
- Lista de elementos
- Modals y dialogs

### 🎨 **Theme**
Sistema de temas y estilos
- Colores de la aplicación
- Tipografía personalizada
- Temas claro/oscuro
- Estilos de componentes
- Configuraciones de Material Design

### 🧭 **Navigation**
Sistema de navegación
- Configuración de rutas
- Guards de navegación
- Transiciones personalizadas
- Deep linking
- Bottom navigation
- Drawer navigation

## 🎯 Estructura Propuesta

```
shared/
├── widgets/
│   ├── common/          # Widgets básicos comunes
│   ├── audio/           # Widgets relacionados con audio
│   ├── forms/           # Elementos de formulario
│   └── layout/          # Widgets de layout
├── theme/
│   ├── app_theme.dart   # Tema principal
│   ├── colors.dart      # Paleta de colores
│   ├── text_styles.dart # Estilos de texto
│   └── dimensions.dart  # Espaciados y tamaños
└── navigation/
    ├── app_router.dart  # Configuración de rutas
    ├── routes.dart      # Definición de rutas
    └── nav_params.dart  # Parámetros de navegación
```

## 🔄 Filosofía de Diseño

1. **Consistencia**: Componentes uniformes en toda la app
2. **Reutilización**: Una vez creado, usado en múltiples lugares
3. **Mantenibilidad**: Cambios centralizados en un solo lugar
4. **Escalabilidad**: Fácil agregar nuevos componentes