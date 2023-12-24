#!/bin/bash
# TOOD: Gitのリポジトリ名がプロジェクト名と異なる場合を検討する
projectName=$1
if [ -z $projectName ]; then
  echo "プロジェクト名を入力してください"
  exit 1
else if [ -z $(aws ecr describe-repositories | grep $projectName\") ]; then
  echo "プロジェクト名が間違っています"
  exit 1
  fi
fi
tagName=$2
if [ -z $tagName ]; then
  echo "タグ名を入力してください"
  exit 1
fi
branchName=$3
if [ -z $branchName ]; then
  read -p "どのブランチにタグを作りますか？: " branchName
  #TODO: 存在しないブランチ名を指定したときのハンドリング
fi
CWD=$(pwd)
WORKDIR=$HOME/.imagebuild
if [ -e $WORKDIR/$projectName ]; then
  cd "$WORKDIR/$projectName"
  git fetch --tags
else
  # FIXME: 必要最低限の情報のみクローンする
  git clone $TAG_BUILDER_REPO_URL/$projectName.git $WORKDIR/$projectName
  cd "$WORKDIR/$projectName"
fi
echo "Tag Creating..."
git tag $tagName remotes/origin/$branchName
git push origin $tagName
echo "Tag Created!"
until git ls-remote --tags -h ssh://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/$projectName | grep refs/tags/$tagName
  do
    echo "Checking..."
    sleep 10
  done
echo "Start build"
aws codebuild start-build --project $projectName --source-version refs/tags/$tagName
# popd
cd $CWD
echo "Completed!"
