set.seed(500)
house1 <- house[ sample ( nrow(house), size= 100 ), ]
# проверить на наличие выбросов

#метод Тьюки

vibr <- subset(house1,house1$Price<quantile(house1$Price, 0.25)-1.5*IQR(house1$Price) |
                 house1$Price>quantile(house1$Price, 0.75)+1.5*IQR(house1$Price))

vibr

boxplot(house1$Price)

#метод z-оценок

shapiro.test(house1$Price)

Z <- subset(house1, abs((house1$Price - mean(house1$Price))/sd(house1$Price))>3)

# Описательная статистика
summary(house1$Price)
sd(house1$Price)
library(e1071)
skewness(house1$Price)
kurtosis(house1$Price)

hist(house1$Price)
library(car)
qqPlot(house1$Price)

# дов инт
t.test(house1$Price, conf.level = 0.95)$conf.int


# разброс очень большой => разделим на группы
# сначала разделим по районам
Rural <- subset(house1, house1$Neighborhood=="Rural")
shapiro.test(Rural$Price)
t.test(Rural$Price, conf.level = 0.95)$conf.int

# предположим, что средняя цена дома за городом равна 220 000 долларов
# H0: mu = 220000
# Ha: mu != 220000
t.test(Rural$Price, mu = 220000, alternative = "two.sided")

# Urban
Urban <- subset(house1, house1$Neighborhood=="Urban")
shapiro.test(Urban$Price)
t.test(Urban$Price, conf.level = 0.95)$conf.int

#Предположим, что средняя цена дома в городе составляет 222 000 долларов
#H0: цена дома в городе равна 222 тыс долларов
#Ha: цена дома в городе отличается от 222 тыс долларов
t.test(Urban$Price, mu = 222000, alternative = "two.sided")
#p-value = 0,1431 => мы не отвергаем гипотезу H0

Suburb <- subset(house1, house1$Neighborhood=="Suburb")
shapiro.test(Suburb$Price)
t.test(Suburb$Price, conf.level = 0.95)$conf.int

#Предположим, что средняя цена дома в пригороде составляет 220 000 долларов
#H0: цена дома в пригороде равна 220 тыс долларов
#Ha: цена дома в пригороде отличается от 210 тыс долларов
t.test(Suburb$Price, mu = 220000, alternative = "two.sided")
#p-value = 0.8049 => мы не отвергаем гипотезу H0

# тест Бартлетта
bartlett.test(Price ~ Neighborhood, data = house1)
# ANOVA
model.aov <- aov(Price ~ Neighborhood, data = house1)
summary(model.aov)

# Город и пригород
var.test(Suburb$Price, Urban$Price)
t.test(Suburb$Price, Urban$Price, var.equal = T, alternative = 'two.sided', paired = F)
#p-value = 0.2645 => не отвергаем гипотезу о равенстве мат ожиданий в пригороде и городе

#пригород и село
var.test(Suburb$Price, Rural$Price)
t.test(Suburb$Price, Rural$Price, var.equal = T, alternative = 'two.sided', paired = F)
#p-value = 0.8479 => не отвергаем гипотезу о равенстве 

#город и село
var.test(Urban$Price, Rural$Price)
t.test(Urban$Price, Rural$Price, var.equal = T, alternative = 'two.sided', paired = F)
#p-value = 0.3612 => не отвергаем гипотезу о равенстве

# сравним три медианы
library(agricolae)
Median.test(house1$Price, house1$Neighborhood, correct = F)
# медианная цена не отличается

# теперь проверим предположение о том, что более старые дома более дешевые 

before1993 <- subset(house1, house1$YearBuilt < 1993)
after1993 <- subset(house1, house1$YearBuilt >= 1993)
shapiro.test(before1993$Price)
shapiro.test(after1993$Price)

# сравниваем не медианы, а мат ожид
var.test(before1993$Price, after1993$Price)
t.test(before1993$Price, after1993$Price, var.equal = T, paired = F, alternative = "greater")

# ANOVA: bathrooms
bartlett.test(Price~as.factor(Bathrooms), data = house1)
aov.bath <- aov(Price~as.factor(Bathrooms), data = house1)
summary(aov.bath)

# ANOVA: bedrooms
bartlett.test(Price~as.factor(Bedrooms), data = house1)
aov.bed <- aov(Price~as.factor(Bedrooms), data = house1)
summary(aov.bed)

# Корреляционный анализ
cor(house1$Price, house1$SquareFeet)
cor(house1$Price, house1$Bedrooms)
cor(house1$Price, house1$Bathrooms)
cor(house1$Price, house1$YearBuilt)

# парная регрессия
regression1 <- lm(Price ~ SquareFeet, data = house1)
summary(regression1)
shapiro.test(regression1$residuals)
install.packages("lmtest")
library(lmtest)
bptest(regression1, studentize = F)
dwtest(regression1)
install.packages("MLmetrics")
library(MLmetrics)
MAPE(regression1$fitted.values, house1$Price)*100

# множественная регрессия
regression2 <- lm(Price ~ SquareFeet + Bedrooms + Bathrooms + YearBuilt, data = house1)
summary(regression2)

# информационный критерий Акаике
AIC(regression1)
AIC(regression2)

# множественная регрессия с качественной переменной
regression3 <- lm(Price ~ SquareFeet + Bedrooms + Bathrooms + YearBuilt + as.factor(Neighborhood), data = house1)
summary(regression3)
AIC(regression3)

# экспортируем файл в эксель, чтобы быстро добавить новую переменную
install.packages("writexl")
library(writexl)
write_xlsx(house1, "C:/Users/Dmitriy/Documents/house1111.xlsx")

# двухфакторная регрессия с переменной before
regression4 <- lm(Price ~ SquareFeet + as.factor(Before), data = house1)
summary(regression4)
