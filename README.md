# my_pdf_helper

## Запуск в режиме разработчика
```
flutter run -d chrome
```

## Билд для деплоя за Nginx
```
flutter build web --release --base-href /my_pdf_helper/
```
Пример Nginx-конфига под такой базовый путь
```
server {
    listen 80;
    server_name your-domain.com;
    root /home/ubuntu/projects_my/my_pdf_helper/build/web;
    location /my_pdf_helper/ {
        alias /home/ubuntu/projects_my/my_pdf_helper/build/web/;
        index index.html;
        try_files $uri $uri/ /my_pdf_helper/index.html;
    }
}
```
