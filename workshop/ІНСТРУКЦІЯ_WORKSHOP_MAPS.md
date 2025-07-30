# Інструкція до workshop-maps.R

## Огляд

Файл `workshop-maps.R` призначений для створення карт та аналізу даних про внутрішньо переміщених осіб (ВПО) в українських громадах. Скрипт використовує дані з опитування сільськогосподарських громад та основний датасет КШЕ для створення візуалізацій.

## Необхідні пакети R

Для роботи скрипту необхідно встановити наступні пакети R:

```r
install.packages(c("tidyverse", "sf", "tmap", "readxl", "janitor", "stargazer", "scales"))
```

### Системні залежності (для Linux/Ubuntu)

Перед встановленням R пакетів потрібно встановити системні бібліотеки:

```bash
sudo apt update
sudo apt install -y libcurl4-openssl-dev libssl-dev libxml2-dev libgdal-dev libudunits2-dev libproj-dev
```

## Файли даних

Скрипт потребує наступних файлів:

1. **agro-survey-workshop.xlsx** - файл з даними опитування (вже присутній в директорії workshop)
2. **full_dataset.csv** - основний датасет КШЕ (розташований в maps/full_dataset.csv)
3. **Геопросторові дані** - полігони громад (завантажуються з GitHub)

## Проблеми з оригінальним скриптом

### 1. Залежність від інтернет-з'єднання
- Скрипт намагається завантажити дані з GitHub
- Без інтернету скрипт не працюватиме

### 2. Відсутність перевірки пакетів
- Скрипт не перевіряє, чи встановлені необхідні пакети
- При відсутності пакетів видає нечіткі помилки

### 3. Неправильний шлях до файлів
- Посилання на файли можуть бути некорректними залежно від робочої директорії

### 4. Проблеми з кодуванням
- Можливі проблеми з українськими символами

## Виправлення (workshop-maps-fixed.R)

Створено виправлену версію скрипту з наступними покращеннями:

### 1. Перевірка пакетів
```r
packages_needed <- c("tidyverse", "sf", "tmap", "readxl", "janitor", "stargazer", "scales")
check_and_install <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    cat("Package", pkg, "not found. Please install it using:\n")
    cat("install.packages('", pkg, "')\n", sep = "")
    return(FALSE)
  }
  return(TRUE)
}
```

### 2. Локальні файли як пріоритет
```r
if (file.exists("../maps/full_dataset.csv")) {
  ds_general <- readr::read_csv("../maps/full_dataset.csv")
} else if (file.exists("../data/derived/full_dataset.csv")) {
  ds_general <- readr::read_csv("../data/derived/full_dataset.csv")
} else {
  # Fallback to GitHub
}
```

### 3. Обробка відсутності геопросторових даних
- Скрипт продовжує роботу навіть без можливості створення карт
- Виконується аналіз даних та створення графіків

### 4. Покращена обробка помилок
- Детальні повідомлення про проблеми
- Graceful degradation при відсутності даних

## Як використовувати

### Варіант 1: З встановленими пакетами та інтернетом
```bash
cd workshop
Rscript workshop-maps.R
```

### Варіант 2: З виправленою версією
```bash
cd workshop
Rscript workshop-maps-fixed.R
```

### Варіант 3: В R консолі
```r
setwd("workshop")
source("workshop-maps-fixed.R")
```

## Вихідні файли

Скрипт створює директорію `workshop-charts` з наступними файлами:

- **idp_numbers_histogram.png** - гістограма кількості ВПО
- **idp_percentage_histogram.png** - гістограма частки ВПО
- **top_bottom_communities.png** - топ та найменші громади за часткою ВПО
- **idp_vs_population.png** - зв'язок між кількістю ВПО та населенням
- **processed_idp_data.csv** - оброблені дані про ВПО
- **regression_data.csv** - дані для регресійного аналізу

## Функціонал скрипту

1. **Завантаження та очищення даних**
   - Читання Excel файлу з опитуванням
   - Злиття з основним датасетом КШЕ
   - Очищення та стандартизація назв

2. **Створення візуалізацій**
   - Гістограми розподілу ВПО
   - Порівняння громад
   - Кореляційні графіки

3. **Статистичний аналіз**
   - Регресійні моделі
   - Фактори, що впливають на кількість ВПО

4. **Картографія** (при наявності геоданих)
   - Статичні карти
   - Інтерактивні карти
   - Карти з різними шарами даних

## Поради з усунення неполадок

### Помилка "Package not found"
```bash
# В R консолі:
install.packages(c("tidyverse", "sf", "tmap", "readxl", "janitor", "stargazer", "scales"))
```

### Помилка "File not found"
- Переконайтеся, що ви в правильній директорії
- Перевірте наявність файлу agro-survey-workshop.xlsx
- Перевірте наявність ../maps/full_dataset.csv

### Проблеми з геопросторовими пакетами
```bash
# Встановіть системні залежності:
sudo apt install -y libgdal-dev libudunits2-dev libproj-dev
```

### Проблеми з кодуванням
```r
# В R, встановіть кодування:
Sys.setlocale("LC_ALL", "UK_UA.UTF-8")
```